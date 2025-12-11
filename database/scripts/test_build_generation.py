import argparse
import csv
import logging
import random
import sys
import uuid
from typing import List, Dict

try:
    import pyodbc
    import requests
    from tqdm import tqdm
except ImportError:
    print("Missing dependencies. Please install: pip install pyodbc requests tqdm", file=sys.stderr)
    sys.exit(1)

# ========================================================================== #
# CONFIGURATION                                                              #
# ========================================================================== #

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

MANDATORY_QUESTIONS = [
    "What do you plan to use your PC for?",
    "What do you do for work?",
    "What's your budget?"
]

# ========================================================================== #
# DATABASE CLASS                                                             #
# ========================================================================== #

class DatabaseConnection:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.conn = None
        self.cursor = None

    def connect(self):
        try:
            self.conn = pyodbc.connect(self.connection_string)
            self.cursor = self.conn.cursor()
        except pyodbc.Error as e:
            logger.error(f"Database connection failed: {e}")
            sys.exit(1)

    def disconnect(self):
        if self.conn:
            self.conn.close()

    def execute(self, query: str, params: tuple = ()):
        return self.cursor.execute(query, params)

    def fetchall(self):
        return self.cursor.fetchall()

    def commit(self):
        self.conn.commit()

# ========================================================================== #
# TEST RUNNER                                                                #
# ========================================================================== #

class BuildGenerationTester:
    def __init__(self, db: DatabaseConnection, api_url: str, auth_token: str, user_id: str):
        self.db = db
        self.api_url = api_url.rstrip('/')
        self.headers = {
            "Authorization": f"Bearer {auth_token}",
            "Content-Type": "application/json"
        }
        self.user_id = user_id
        self.questions: Dict[str, Dict] = {} # Map Question Text -> {Id, Answers: []}
        self.all_answer_ids: List[str] = []

    def load_metadata(self):
        """Load questions and answers from the database."""
        logger.info("Loading questionnaire metadata...")
        
        # Get Questions
        query_q = "SELECT Id, Question FROM UserPreferences"
        self.db.execute(query_q)
        for row in self.db.fetchall():
            q_id, q_text = str(row.Id), row.Question
            self.questions[q_text] = {"id": q_id, "answers": []}

        # Get Answers
        query_a = "SELECT Id, UserPreferenceId, Answer FROM UserPreferenceAnswers"
        self.db.execute(query_a)
        for row in self.db.fetchall():
            a_id, q_id, a_text = str(row.Id), str(row.UserPreferenceId), row.Answer
            self.all_answer_ids.append(a_id)
            
            # Find which question this answer belongs to
            for q_text, q_data in self.questions.items():
                if q_data["id"] == q_id:
                    q_data["answers"].append({"id": a_id, "text": a_text})
                    break
        
        logger.info(f"Loaded {len(self.questions)} questions and {len(self.all_answer_ids)} answers.")

    def clear_user_data(self):
        """Clear answers and builds for the test user."""
        # Delete UserAnswers
        self.db.execute("DELETE FROM UserAnswers WHERE UserId = ?", (self.user_id,))
        
        # Delete Builds (Cascade should handle BuildComponents, but we can be explicit if needed)
        self.db.execute("DELETE FROM Builds WHERE UserId = ? AND (Status = 'GENERATED')", (self.user_id,))
        self.db.commit()

    def insert_answers(self, answer_ids: List[str]):
        """Insert selected answers for the user."""
        if not answer_ids:
            return

        values = []
        for a_id in answer_ids:
            # We need the UserPreferenceId for the answer
            # Find it in our metadata
            q_id = None
            for q_data in self.questions.values():
                for ans in q_data["answers"]:
                    if ans["id"] == a_id:
                        q_id = q_data["id"]
                        break
                if q_id: break
            
            if q_id:
                # (Id, UserId, UserPreferenceAnswerId, DatabaseEntryAt, LastEditedAt)
                values.append((str(uuid.uuid4()), self.user_id, a_id))

        query = """
            INSERT INTO UserAnswers (Id, UserId, UserPreferenceAnswerId, DatabaseEntryAt, LastEditedAt)
            VALUES (?, ?, ?, GETUTCDATE(), GETUTCDATE())
        """
        self.db.cursor.executemany(query, values)
        self.db.commit()

    def trigger_generation(self) -> bool:
        """Call the API to generate builds."""
        try:
            response = requests.post(f"{self.api_url}/Builds/generate", headers=self.headers)
            if response.status_code == 200:
                return True
            else:
                logger.warning(f"API Call Failed: {response.status_code} - {response.text}")
                return False
        except requests.RequestException as e:
            logger.error(f"API Connection Error: {e}")
            return False

    def get_generated_results(self) -> List[Dict]:
        """Fetch the generated builds and their components from DB."""
        results = []
        
        # Get Builds
        query_builds = """
            SELECT Id, Name, Status, DatabaseEntryAt 
            FROM Builds 
            WHERE UserId = ? AND Status = 'GENERATED'
            ORDER BY DatabaseEntryAt DESC
        """
        self.db.execute(query_builds, (self.user_id,))
        builds = self.db.fetchall()

        for build in builds:
            build_id = str(build.Id)
            
            # Get Components for this build
            query_comps = """
                SELECT c.Id, c.Name, c.Type, 
                       (SELECT TOP 1 Price FROM ComponentPrice cp 
                        WHERE cp.ComponentId = c.Id 
                        ORDER BY cp.FetchedAt DESC) as Price
                FROM BuildComponents bc
                JOIN Components c ON bc.ComponentId = c.Id
                WHERE bc.BuildId = ?
            """
            self.db.execute(query_comps, (build_id,))
            components = self.db.fetchall()
            
            comp_list = []
            total_price = 0.0
            for c in components:
                price = float(c.Price) if c.Price else 0.0
                comp_list.append(f"{c.Name} (${price})")
                total_price += price

            results.append({
                "BuildId": build_id,
                "BuildName": build.Name,
                "TotalPrice": total_price,
                "ComponentCount": len(components),
                "Components": "; ".join(comp_list)
            })
            
        return results

    def generate_random_scenario(self, mode: str) -> List[str]:
        """Generate a list of answer IDs based on the mode."""
        selected_answers = []
        
        # Helper to get answers from a question
        def get_answers_for_question(q_text):
            if q_text in self.questions and self.questions[q_text]["answers"]:
                return self.questions[q_text]["answers"]
            return None

        all_questions = list(self.questions.keys())
        mandatory_questions = [q for q in all_questions if q in MANDATORY_QUESTIONS]
        optional_questions = [q for q in all_questions if q not in MANDATORY_QUESTIONS]

        # Helper to pick n random answers
        def pick_random_answers(answers, min_k=1, max_k=1):
            if not answers: return []
            k = random.randint(min_k, min(max_k, len(answers)))
            return [a["id"] for a in random.sample(answers, k)]

        if mode == "min":
            # Only mandatory, 1 answer each
            for q in mandatory_questions:
                ans = get_answers_for_question(q)
                selected_answers.extend(pick_random_answers(ans, 1, 1))

        elif mode == "all":
            # All answers for all questions
            selected_answers = self.all_answer_ids

        elif mode == "single":
            # 1 answer for every question selected (mandatory + random optional)
            # Mandatory: 1 each
            for q in mandatory_questions:
                ans = get_answers_for_question(q)
                selected_answers.extend(pick_random_answers(ans, 1, 1))
            
            # Optional: Randomly decide to answer or not, if yes, 1 answer
            for q in optional_questions:
                if random.random() > 0.5:
                    ans = get_answers_for_question(q)
                    selected_answers.extend(pick_random_answers(ans, 1, 1))

        elif mode == "small":
            # Mandatory (1-3 answers) + 0-3 optional answers total
            
            # Mandatory: Random 1 to 3
            for q in mandatory_questions:
                ans = get_answers_for_question(q)
                selected_answers.extend(pick_random_answers(ans, 1, 3))
            
            # Optional: Pick 0-3 answers total across all optional questions
            optional_pool = []
            for q in optional_questions:
                optional_pool.extend([a["id"] for a in get_answers_for_question(q)])
            
            if optional_pool:
                count = random.randint(0, 3)
                selected_answers.extend(random.sample(optional_pool, min(count, len(optional_pool))))

        elif mode == "random":
            # Mandatory (1-all) + random optional
            for q in mandatory_questions:
                ans = get_answers_for_question(q)
                selected_answers.extend(pick_random_answers(ans, 1, len(ans)))
            
            for q in optional_questions:
                if random.random() > 0.5:
                    ans = get_answers_for_question(q)
                    # Random number of answers for this question
                    selected_answers.extend(pick_random_answers(ans, 1, len(ans)))

        elif mode == "large":
            # Mandatory (1-all) + almost all optional
            for q in mandatory_questions:
                ans = get_answers_for_question(q)
                selected_answers.extend(pick_random_answers(ans, 1, len(ans)))
            
            for q in optional_questions:
                if random.random() > 0.1: # 90% chance to answer question
                    ans = get_answers_for_question(q)
                    # High chance to pick many answers
                    selected_answers.extend(pick_random_answers(ans, max(1, len(ans)-1), len(ans)))

        return list(set(selected_answers))

# ========================================================================== #
# MAIN                                                                       #
# ========================================================================== #

def main():
    parser = argparse.ArgumentParser(description="Test Build Generation Logic")
    parser.add_argument("--connection-string", required=True, help="ODBC Connection String")
    parser.add_argument("--api-url", required=True, help="Base URL of the API (e.g., http://localhost:7249)")
    parser.add_argument("--auth-token", required=True, help="Bearer token for a valid user")
    parser.add_argument("--user-id", required=True, help="UUID of the user the token belongs to")
    parser.add_argument("--iterations", type=int, default=1000, help="Number of test iterations")
    parser.add_argument("--output", default="build_generation_test_results.csv", help="Output CSV file")
    
    args = parser.parse_args()

    db = DatabaseConnection(args.connection_string)
    db.connect()

    tester = BuildGenerationTester(db, args.api_url, args.auth_token, args.user_id)
    tester.load_metadata()

    # Define scenario distribution
    modes = ["min", "single", "small", "random", "large"]
    
    logger.info(f"Starting test with {args.iterations} iterations...")

    # Prepare list of scenarios to run
    scenarios_to_run = []

    # Run the 'All' Scenario once
    scenarios_to_run.append("all")
    
    # Fill the rest of scenarios with random distribution
    remaining = args.iterations - 1
    if remaining > 0:
        for _ in range(remaining):
            scenarios_to_run.append(random.choice(modes))

    with open(args.output, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['ScenarioMode', 'Success', 'BuildCount', 'TotalPrice', 'BuildName', 'Components', 'SelectedAnswerCount', 'SelectedAnswers']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for i, mode in tqdm(enumerate(scenarios_to_run), total=len(scenarios_to_run)):
            # 1. Generate Scenario
            answer_ids = tester.generate_random_scenario(mode)
            
            # 2. Setup DB
            tester.clear_user_data()
            tester.insert_answers(answer_ids)
            
            # 3. Trigger API
            success = tester.trigger_generation()
            
            # 4. Check Results
            results = tester.get_generated_results()
            
            # 5. Log
            if not results:
                writer.writerow({
                    'ScenarioMode': mode,
                    'Success': success,
                    'BuildCount': 0,
                    'TotalPrice': 0,
                    'BuildName': "N/A",
                    'Components': "",
                    'SelectedAnswerCount': len(answer_ids),
                    'SelectedAnswers': str(answer_ids)
                })
            else:
                for res in results:
                    writer.writerow({
                        'ScenarioMode': mode,
                        'Success': success,
                        'BuildCount': len(results),
                        'TotalPrice': res['TotalPrice'],
                        'BuildName': res['BuildName'],
                        'Components': res['Components'],
                        'SelectedAnswerCount': len(answer_ids),
                        'SelectedAnswers': str(answer_ids)
                    })
            
            csvfile.flush()

    # Final Cleanup
    tester.clear_user_data()
    db.disconnect()
    logger.info(f"Test completed. See output CSV for details - {args.output}.")

if __name__ == "__main__":
    main()