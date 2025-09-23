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
                //Check if the term is a negation
                var isExclusion = term.StartsWith('-');
                //If it is a negation remove the dash
                var cleanTerm = isExclusion ? term[1..] : term;

                if (cleanTerm.Contains(':')) //Field-specific search e.g. "email:test@example.com"
                {
                    //Split into the field name and value to search
                    var parts = cleanTerm.Split(':', 2);
                    var fieldName = parts[0];
                    var value = parts[1].Trim('"');

                    //Call the function to build the filter and apply it to get filtered objects
                    var filter = ApplyFieldFilter(query, fieldName, value);

                    //Apply the exclusion if it's a negation
                    query = isExclusion
                       ? query.Except(filter)
                       : filter;
                }
                else //General search across all searchable fields
                {
                    //Build expression for filtering the query using all searchable fields, prune null ones
                    var predicates = searchableFields
                        .Select(expr => BuildContainsExpression(expr, cleanTerm.Trim('"')))
                        .Where(p => p != null)
                        .ToList();

                    //Filter the query by combining the build predicates
                    if (predicates.Count > 0)
                    {
                        var combined = predicates.Aggregate((p1, p2) => p1.OrElse(p2));
                        query = isExclusion
                            ? query.Where(Expression.Lambda<Func<T, bool>>(Expression.Not(combined.Body), combined.Parameters))
                            : query.Where(combined);
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

            //Wrap the expression into a lambda and return the filtered query
            var lambda = Expression.Lambda<Func<T, bool>>(body, param);
            return query.Where(lambda);
        }

        //Build a full-text contains expression, e.g. (x.Name.Contains("term"))
        private static Expression<Func<T, bool>> BuildContainsExpression<T>(Expression<Func<T, object>> field, string value, int minResults = 10, int levenshteinTolerance = 1, int soundexThreshold = 3)
        {
            //Get the parameter "x"
            var param = field.Parameters[0];
            //Declare the expression to build
            Expression body = field.Body;

            //Unwrap the expression body to the actual member if it's an object
            if (body is UnaryExpression unary && unary.Operand is MemberExpression)
                body = unary.Operand;

            //Only strings should be searched in the full-text search
            if (body.Type != typeof(string))
                return null!;

            //Call the contains function imported from SQL
            var method = typeof(FullTextDbFunction).GetMethod(nameof(FullTextDbFunction.Contains))!;

            //Build the contains expression
            var containsCall = Expression.Call(method, body, Expression.Constant(value));

            //Build the expression into a lambda to test the amount of results
            var containsLambda = Expression.Lambda<Func<T, bool>>(containsCall, field.Parameters);

            //Wrap the expression into a lambda and return it
            return Expression.Lambda<Func<T, bool>>(containsCall, param);
        }

        //Fuzzy matching helper function
        public static bool FuzzyMatch(string? source, string target, int tolerance)
        {
            //Check if the string is not empty
            if (string.IsNullOrEmpty(source)) return false;

            //return if the value is within tolerance
            return LevenshteinDistance(source.ToLower(), target.ToLower()) <= tolerance;
        }

        //Check how far away the target is for the fuzzy match
        public static int LevenshteinDistance(string s, string t)
        {
            //Check if the string length allows using the function
            if (string.IsNullOrEmpty(s)) return t?.Length ?? 0;
            if (string.IsNullOrEmpty(t)) return s.Length;

            //Declare necessary variables
            var n = s.Length;
            var m = t.Length;
            var d = new int[n + 1, m + 1]; //Helper array for storing the edit distance

            //Fill the array edges with initial values for the string length
            for (int i = 0; i <= n; i++) d[i, 0] = i;
            for (int j = 0; j <= m; j++) d[0, j] = j;

            //Calculate the Levenshtein distance
            for (int i = 1; i <= n; i++)
            {
                for (int j = 1; j <= m; j++)
                {
                    //Check if there a difference between the specified characters
                    int cost = (s[i - 1] == t[j - 1]) ? 0 : 1;

                    //Take the minimum cost of deleting, inserting or substituting a character
                    d[i, j] = Math.Min(Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1), d[i - 1, j - 1] + cost);
                }
            }

            //return the last cell of the array which stores the final value of edit distance
            return d[n, m];
        }

        //Expression helper that combines two lambdas with a logical OR, e.g. Name.Contains("a") OR Email.Contains("a")
        private static Expression<Func<T, bool>> OrElse<T>(this Expression<Func<T, bool>> expr1, Expression<Func<T, bool>> expr2)
        {
            //Ensure both lambdas use the same parameter "x" and join them together
            var param = expr1.Parameters[0];
            var body = Expression.OrElse(expr1.Body, new ReplaceParameterVisitor(expr2.Parameters[0], param).Visit(expr2.Body)!);

            //Wrap the combined expression into a lambda and return it
            return Expression.Lambda<Func<T, bool>>(body, param);
        }

        //Helper for Swapping a parameter in a lambda, required because of EF functioning
        private class ReplaceParameterVisitor(ParameterExpression oldParam, ParameterExpression newParam) : ExpressionVisitor
        {
            private readonly ParameterExpression _oldParam = oldParam;
            private readonly ParameterExpression _newParam = newParam;

            protected override Expression VisitParameter(ParameterExpression node)
                => node == _oldParam ? _newParam : node;
        }

        //Regex generator, creates the regex once at launch
        [GeneratedRegex(@"(\w+:[\""].+?[\""])|([\""].+?[\""])|(\S+)")]
        private static partial Regex SearchTermRegex();
    }
}
