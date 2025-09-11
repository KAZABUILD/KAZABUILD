using Microsoft.EntityFrameworkCore.Query.SqlExpressions;
using System.Linq.Expressions;
using System.Reflection;
using System.Text.RegularExpressions;

namespace KAZABUILD.Application.Helpers
{
    //Handles Search functionality in controllers
    public static partial class SearchHelper
    {
        //Helper for searching in queries, takes in the search string and all the fields used for search;
        //Split search string into tokens and apply them one by one.
        //Tokens with ":" are treated as field-specific (field:value),
        //tokens without ":" are searched across all provided searchable fields
        public static IQueryable<T> Search<T>(this IQueryable<T> query, string? search, params Expression<Func<T, object>>[] searchableFields)
        {
            //If the search is empty return every object in query
            if (string.IsNullOrWhiteSpace(search)) return query;

            //Split the query string into words separated by whitespaces,
            //but treat characters wrapped with quotation marks as one word
            var terms = SearchTermRegex()
                .Matches(search)
                .Select(m => m.Value)
                .ToArray();

            //Search all words
            foreach (var term in terms)
            {
                if (term.Contains(':')) //Field-specific search e.g. "email:test@example.com"
                {
                    //Split into the field name and value to search
                    var parts = term.Split(':', 2);
                    var fieldName = parts[0];
                    var value = parts[1].Trim('"');

                    //Call the function to build the filter and apply it to get filtered objects
                    query = ApplyFieldFilter(query, fieldName, value);
                }
                else //General search across all searchable fields
                {
                    //Build expression for filtering the query using all searchable fields, prune null ones
                    var predicates = searchableFields
                        .Select(expr => BuildContainsExpression(expr, term.Trim('"')))
                        .Where(p => p != null)
                        .ToList();

                    //Filter the query by combining the build predicates
                    if (predicates.Count != 0)
                    {
                        var combined = predicates.Aggregate((p1, p2) => p1.OrElse(p2));
                        query = query.Where(combined);
                    }
                }
            }

            //return the filtered query
            return query;
        }

        //Function that allows thorough field-specific search with semicolons, e.g. "email:test@example.com"
        private static IQueryable<T> ApplyFieldFilter<T>(IQueryable<T> query, string fieldName, string value)
        {
            //Create the parameter for the field, e.g. (x => x.Email)
            var param = Expression.Parameter(typeof(T), "x");
            //Get the property info by name from the class and check if it exists
            var property = typeof(T).GetProperty(fieldName, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);
            if (property == null) return query;

            //Declare the expression to build
            Expression body;

            //Handle numbers/dates with comparison (greater/less than)
            if (value.StartsWith('>') || value.StartsWith('<'))
            {
                //Separate the sign and value
                var op = value[0];
                var raw = value[1..];

                //Parse to the correct type
                object? parsed = Convert.ChangeType(raw, property.PropertyType);

                //Create the left and right side of the expression
                var left = Expression.Property(param, property);
                var right = Expression.Constant(parsed);

                //Build the expression based on which sign was used, e.g. (x => x.Count < 5)
                body = op switch
                {
                    '>' => Expression.GreaterThan(left, right),
                    '<' => Expression.LessThan(left, right),
                    _ => throw new InvalidOperationException()
                };
            }
            else //If no > or < use defaults equals check
            {
                //Create the left and right side of the expression
                var left = Expression.Property(param, property);
                var right = Expression.Constant(Convert.ChangeType(value, property.PropertyType));

                //Build an equals expression, e.g. (x => x.Email == "foo@bar.com")
                body = Expression.Equal(left, right);
            }

            //Wrap the expression into a lamda and return the filtered query
            var lambda = Expression.Lambda<Func<T, bool>>(body, param);
            return query.Where(lambda);
        }

        //Build the default contains expression, e.g. (x.Name.Contains("term"))
        private static Expression<Func<T, bool>> BuildContainsExpression<T>(Expression<Func<T, object>> field, string value)
        {
            //Get the parameter "x"
            var param = field.Parameters[0];
            //Declare the expression to build
            Expression body = field.Body;

            //Unwrap the the expression body to the actual member if it's an object
            if (body is UnaryExpression unary && unary.Operand is MemberExpression)
                body = unary.Operand;

            //Only strings can be searched in the general search
            if (body.Type != typeof(string)) return null!;

            //Build the contains expression, e.g. (x.Name.Contains("value"))
            var method = typeof(string).GetMethod("Contains", [typeof(string)])!;
            var call = Expression.Call(body, method, Expression.Constant(value));
            //Create a null check expression for the type
            var notNull = Expression.NotEqual(body, Expression.Constant(null, typeof(string)));
            //Combine it so the expression cannot be null
            var combined = Expression.AndAlso(notNull, call);

            //Wrap the expression into a lamda and return it
            return Expression.Lambda<Func<T, bool>>(combined, param);
        }

        //Expression helper that combines two lambdas with a logical OR, e.g. Name.Contains("a") OR Email.Contains("a")
        private static Expression<Func<T, bool>> OrElse<T>(this Expression<Func<T, bool>> expr1, Expression<Func<T, bool>> expr2)
        {
            //Ensure both lamndas use the same parameter "x" and join them together
            var param = expr1.Parameters[0];
            var body = Expression.OrElse(expr1.Body, new ReplaceParameterVisitor(expr2.Parameters[0], param).Visit(expr2.Body)!);

            //Wrap the combined expression into a lamda and return it
            return Expression.Lambda<Func<T, bool>>(body, param);
        }

        //Helper for Swapping a parameter in a lambda, required because of EF functionining
        private class ReplaceParameterVisitor(ParameterExpression oldParam, ParameterExpression newParam) : ExpressionVisitor
        {
            private readonly ParameterExpression _oldParam = oldParam;
            private readonly ParameterExpression _newParam = newParam;

            protected override Expression VisitParameter(ParameterExpression node)
                => node == _oldParam ? _newParam : node;
        }

        //Regex generator, created the regex once at launch
        [GeneratedRegex(@"(\w+:[\""].+?[\""])|([\""].+?[\""])|(\S+)")]
        private static partial Regex SearchTermRegex();
    }
}
