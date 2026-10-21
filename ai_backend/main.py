import json
import random
import threading
import time

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import requests

app = FastAPI(
    title="TalkiePal Parent AI",
    description="AI speech and language development guidance for parents",
    version="1.0.0"
)

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
MODEL_NAME = "llama3.2:3b"

# Keep the model loaded in memory so kids do not wait for it to reload.
OLLAMA_KEEP_ALIVE = "30m"


def warm_up_model():
    """Load the model into memory when the backend starts."""
    try:
        requests.post(
            "http://127.0.0.1:11434/api/generate",
            json={"model": MODEL_NAME, "keep_alive": OLLAMA_KEEP_ALIVE},
            timeout=120
        )
    except requests.RequestException:
        pass  # Ollama not running yet; the first request will load it.


@app.on_event("startup")
def start_warm_up():
    # Run in the background so the server starts immediately.
    threading.Thread(target=warm_up_model, daemon=True).start()


SYSTEM_PROMPT = """
You are TalkiePal AI, a friendly, patient, and supportive
speech and language development assistant for parents.

ABOUT TALKIEPAL:
TalkiePal is a mobile application designed to support
children aged 2 to 12 with speech and pronunciation
practice.

YOUR ROLE:
Help parents support their children's speech, language,
pronunciation, and communication development.

LANGUAGE RULES:
1. ALWAYS respond in ENGLISH ONLY.
2. Never respond in Malay or any other language.
3. If the parent writes in another language, understand
   the question but answer entirely in English.
4. Use simple, clear, and natural English.
5. Avoid complicated medical terminology.

AREAS YOU CAN HELP WITH:
- Children's speech and language development.
- Pronunciation of R, S, L, TH, and SH sounds.
- Speech and language activities at home.
- Helping children learn new words.
- Encouraging communication through play.
- Picture cards, flashcards, songs, and storytelling.
- Supporting children who are reluctant to speak.
- General communication support for autistic children.
- Helping parents understand when professional
  assessment may be needed.

RESPONSE GUIDELINES:
1. Answer the parent's question directly.
2. Be friendly, supportive, and respectful.
3. Give 2 to 4 practical suggestions when appropriate.
4. Explain activities using simple steps.
5. Adapt suggestions to the child's age when provided.
6. Keep answers concise, usually 80 to 150 words.
7. Encourage parents to praise effort and avoid pressure.
8. Ask a follow-up question only when helpful.
9. Never invent information about the child.

IMPORTANT SAFETY RULES:
1. Never diagnose autism, speech disorders, hearing loss,
   or other developmental conditions.
2. Never claim to replace a speech-language therapist,
   doctor, or audiologist.
3. Never promise that exercises will cure speech delays.
4. Do not blame parents or children.
5. Do not recommend forcing children to speak.
6. Do not recommend punishment or withholding basic needs
   to encourage communication.
7. If a child has lost previously acquired language skills,
   advise prompt professional assessment.
8. If a 5-year-old cannot speak or uses very few words,
   recommend prompt speech-language assessment and
   a hearing evaluation.
9. For persistent concerns at any age, encourage
   professional assessment instead of waiting.
10. Home activities should support, not replace,
    professional assessment.

PRONUNCIATION PRACTICE:
When parents ask about R, S, L, TH, or SH sounds:
- Suggest simple, age-appropriate practice words.
- Use playful activities and picture games.
- Recommend short and enjoyable practice sessions.
- Encourage natural sound modelling.
- Never pressure children to repeat difficult sounds.

AUTISM COMMUNICATION SUPPORT:
- Use respectful, supportive language.
- Recognize different communication styles.
- Encourage meaningful communication.
- Suggest visual supports, gestures, and play.
- Never claim that autism can be cured.

EXAMPLE:

Parent:
"My 5-year-old son cannot speak. What should I do?"

TalkiePal AI:
"If your son is 5 years old and is not speaking,
please arrange an assessment with a qualified
speech-language therapist and have his hearing checked.

While waiting, you can try:
1. Picture books: Name familiar objects together.
2. Simple choices: Offer two toys and let him
   communicate through words, gestures, or pointing.
3. Playtime: Describe activities using short sentences.

Praise every attempt to communicate and avoid
pressuring him to repeat words.

These activities can help support communication,
but they should not delay professional assessment."

FINAL RULE:
Always respond in English only.
Never switch to Malay or another language.
"""


class ChatRequest(BaseModel):
    message: str = Field(
        min_length=1,
        max_length=1000
    )


class ChatResponse(BaseModel):
    reply: str


@app.get("/")
def home():
    return {
        "app": "TalkiePal Parent AI",
        "status": "running",
        "model": MODEL_NAME,
        "language": "English"
    }


@app.get("/health")
def health():
    return {
        "status": "running",
        "service": "TalkiePal AI Backend"
    }


@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest):

    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty."
        )

    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": MODEL_NAME,
                "stream": False,
                "messages": [
                    {
                        "role": "system",
                        "content": SYSTEM_PROMPT
                    },
                    {
                        "role": "user",
                        "content": message
                    }
                ],
                "options": {
                    "temperature": 0.3,
                    "num_predict": 300
                }
            },
            timeout=120
        )

        response.raise_for_status()

        data = response.json()
        reply = data["message"]["content"].strip()

        if not reply:
            raise ValueError("Empty response from Llama")

        return ChatResponse(reply=reply)

    except requests.Timeout:
        raise HTTPException(
            status_code=504,
            detail="Llama took too long to respond."
        )

    except requests.RequestException:
        raise HTTPException(
            status_code=503,
            detail="Cannot connect to Llama. Check Ollama."
        )

    except (KeyError, TypeError, ValueError):
        raise HTTPException(
            status_code=502,
            detail="Invalid response from Llama."
        )


# ---------------------------------------------------------------
# AI-GENERATED PRACTICE EXERCISES
# ---------------------------------------------------------------

# Rules the model must follow for each level. Only "beginner"
# is enabled for now; add more levels here when ready.
LEVEL_RULES = {
    "beginner": {
        "description": "children aged 3 to 6 who are just starting to speak English",
        "word_rule": "ONE single, simple, common English word (no spaces, no hyphens)",
        "min_words": 1,
        "max_words": 1,
        "max_length": 10,
        "example": {"word": "CAT", "emoji": "🐱"},
    },
    "pre_intermediate": {
        "description": "children aged 5 to 8 who know basic English words and are starting to join words together",
        "word_rule": "a short, simple phrase or sentence of 2 to 4 easy words (for example BRUSH TEETH or I AM HAPPY), no punctuation and no apostrophes",
        "min_words": 2,
        "max_words": 4,
        "max_length": 30,
        "example": {"word": "I AM HAPPY", "emoji": "😊"},
    },
    "special_words": {
        "description": "children who are practising one difficult speech sound",
        "word_rule": "ONE simple, common English word that contains the target sound (no spaces, no hyphens)",
        "extra_rule": "Mix words with the sound at the START, in the MIDDLE and at the END (for example {hint}).",
        "min_words": 1,
        "max_words": 1,
        "max_length": 12,
        "example": {"word": "RED", "emoji": "🔴"},
    },
    "special_sentences": {
        "description": "children who are practising one difficult speech sound in sentences",
        "word_rule": "a short, simple sentence of 3 to 8 easy words, no punctuation and no apostrophes",
        "extra_rule": "At least 3 words in each sentence must contain the target sound (for example {hint}).",
        "min_words": 3,
        "max_words": 8,
        "max_length": 50,
        "example": {"word": "THE RED ROBOT RUNS IN THE RAIN", "emoji": "🤖"},
    },
}

# Target sounds for Special Sound practice.
# "avoid" lists spellings that sound different and would confuse the child.
SPECIAL_SOUNDS = {
    "R": {"hint": "RED, CARROT, CAR", "avoid": ["WR"]},
    "S": {"hint": "SUN, BASKET, BUS", "avoid": ["SH"]},
    "L": {"hint": "LEG, BALLOON, BALL", "avoid": []},
    "TH": {"hint": "THREE, MOTHER, BATH", "avoid": []},
    "SH": {"hint": "SHIP, WASHING, FISH", "avoid": []},
    "CH": {"hint": "CHIN, TEACHER, LUNCH", "avoid": ["CHR"]},
    "V": {"hint": "VAN, SEVEN, FIVE", "avoid": []},
    "W": {"hint": "WET, WINDOW, SANDWICH", "avoid": ["WR", "WH"]},
}

# Topics allowed for each level, with a hint to keep the model on track.
LEVEL_TOPICS = {
    "beginner": {
        "Colors": "basic colour names",
        "Animals": "common animals children know",
        "Fruits": "common fruits",
        "Body Parts": "parts of the human body",
        "Clothes": "everyday clothing items",
        "Vehicles": "common vehicles and transport",
    },
    "pre_intermediate": {
        "My Morning Routine": "things a child does in the morning, e.g. I WAKE UP",
        "My Feelings": "simple feelings, e.g. I AM HAPPY",
        "Things I Like": "activities a child likes, e.g. I LIKE TO DRAW",
        "School & Classroom": "people, objects and actions at school",
        "Hobbies & Free Time": "fun activities, e.g. PLAYING FOOTBALL",
        "Daily Routine": "everyday actions, e.g. EAT BREAKFAST",
        "Home & Rooms": "rooms and things at home, e.g. LIVING ROOM",
        "Shopping & Toys": "toys and shopping items, e.g. TEDDY BEAR",
    },
    "special_words": {
        sound: f'the "{sound}" sound, spelled {sound}' for sound in SPECIAL_SOUNDS
    },
    "special_sentences": {
        sound: f'the "{sound}" sound, spelled {sound}' for sound in SPECIAL_SOUNDS
    },
}

EXERCISE_SCHEMA = {
    "type": "object",
    "properties": {
        "exercises": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "word": {"type": "string"},
                    "emoji": {"type": "string"},
                },
                "required": ["word", "emoji"],
            },
        }
    },
    "required": ["exercises"],
}


class ExerciseRequest(BaseModel):
    level: str = Field(min_length=1, max_length=40)
    topic: str = Field(min_length=1, max_length=40)
    count: int = Field(default=10, ge=1, le=10)
    exclude: list[str] = Field(default_factory=list, max_length=50)


class Exercise(BaseModel):
    word: str
    emoji: str


class ExerciseResponse(BaseModel):
    level: str
    topic: str
    exercises: list[Exercise]


def build_exercise_prompt(level: str, topic: str, count: int, exclude: list[str]) -> str:
    rules = LEVEL_RULES[level]
    topic_hint = LEVEL_TOPICS[level][topic]
    avoid = ", ".join(w.upper() for w in exclude) or "none"

    extra = ""
    if level in ("special_words", "special_sentences"):
        sound = SPECIAL_SOUNDS[topic]
        extra = "\n7. " + rules["extra_rule"].format(hint=sound["hint"])
        if sound["avoid"]:
            extra += f"\n8. Do not use any word spelled with {' or '.join(sound['avoid'])}."

    return f"""
Create {count} different speaking practice items for {rules["description"]}.

TOPIC: {topic} ({topic_hint})

RULES:
1. Each item is {rules["word_rule"]}.
2. Every item MUST belong to the topic "{topic}".
3. Use easy, child-friendly, everyday words only.
4. No duplicates. Do not use these: {avoid}.
5. "word" must be in UPPERCASE letters only.
6. "emoji" is ONE emoji that shows the item.{extra}

Reply with JSON only, for example:
{json.dumps({"exercises": [rules["example"]]}, ensure_ascii=False)}
"""


def has_target_sound(text: str, topic: str, level: str) -> bool:
    """For Special Sound levels, check the target sound is there and no confusing sound is."""
    if level not in ("special_words", "special_sentences"):
        return True

    target = topic.upper()
    avoid = SPECIAL_SOUNDS[topic]["avoid"]
    words = text.split()

    if any(bad in word for word in words for bad in avoid):
        return False

    needed = 1 if level == "special_words" else 3
    return sum(target in word for word in words) >= needed


def clean_exercises(raw_items, level: str, topic: str, count: int, exclude: list[str]) -> list[Exercise]:
    """Keep only valid, unique words that match the level rules."""
    rules = LEVEL_RULES[level]
    seen = {w.strip().upper() for w in exclude}
    cleaned = []

    for item in raw_items:
        if not isinstance(item, dict):
            continue

        parts = str(item.get("word", "")).upper().split()
        word = " ".join(parts)
        emoji = str(item.get("emoji", "")).strip()[:8]

        if not word or word in seen:
            continue
        if not rules["min_words"] <= len(parts) <= rules["max_words"]:
            continue
        if not all(part.isalpha() and part.isascii() for part in parts):
            continue
        if len(word) > rules["max_length"]:
            continue
        if not has_target_sound(word, topic, level):
            continue

        seen.add(word)
        cleaned.append(Exercise(word=word, emoji=emoji or "⭐"))

        if len(cleaned) == count:
            break

    return cleaned


def ask_llama_json(prompt: str, schema: dict, num_predict: int) -> dict:
    """Ask Llama for JSON that follows the schema. Raises HTTPException on failure."""
    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": MODEL_NAME,
                "stream": False,
                "keep_alive": OLLAMA_KEEP_ALIVE,
                "format": schema,
                "messages": [
                    {
                        "role": "system",
                        "content": "You create safe English speaking practice for young children. You always reply with valid JSON only."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "options": {
                    # Higher temperature so each session gets new content.
                    "temperature": 0.9,
                    "num_predict": num_predict
                }
            },
            timeout=180
        )

        response.raise_for_status()

        return json.loads(response.json()["message"]["content"])

    except requests.Timeout:
        raise HTTPException(
            status_code=504,
            detail="Llama took too long to respond."
        )

    except requests.RequestException:
        raise HTTPException(
            status_code=503,
            detail="Cannot connect to Llama. Check Ollama."
        )

    except (KeyError, TypeError, ValueError):
        # json.JSONDecodeError is a ValueError
        raise HTTPException(
            status_code=502,
            detail="Invalid response from Llama."
        )


@app.post("/generate-exercises", response_model=ExerciseResponse)
def generate_exercises(request: ExerciseRequest):

    level = request.level.strip().lower()
    topic = request.topic.strip()

    if level not in LEVEL_RULES:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown level: {request.level}"
        )

    if topic not in LEVEL_TOPICS[level]:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown topic for {level}: {request.topic}"
        )

    started = time.time()

    data = ask_llama_json(
        build_exercise_prompt(level, topic, request.count, request.exclude),
        EXERCISE_SCHEMA,
        num_predict=800
    )

    try:
        exercises = clean_exercises(data["exercises"], level, topic, request.count, request.exclude)
    except (KeyError, TypeError):
        exercises = []

    if not exercises:
        raise HTTPException(
            status_code=502,
            detail="Invalid response from Llama."
        )

    print(f"[generate-exercises] {level}/{topic}: {len(exercises)} words in {time.time() - started:.1f}s")

    return ExerciseResponse(level=level, topic=topic, exercises=exercises)


# ---------------------------------------------------------------
# AI-GENERATED QUESTIONS (INTERMEDIATE)
# ---------------------------------------------------------------

QUESTION_TOPICS = {
    "About Me": "questions about the child, e.g. name, age, family, favourite things",
    "Daily Routine": "questions about the child's day, e.g. waking up, meals, going to school",
    "My School": "questions about school, e.g. teacher, subjects, friends, recess",
    "Travel & Holiday": "questions about holidays and trips, e.g. where you went, how you travelled",
    "Weather & Seasons": "questions about the weather, e.g. sunny, rainy, hot, what you wear",
    "Feelings & Emotion": "questions about feelings, e.g. how you feel, what makes you happy",
    "Places Around Town": "questions about places, e.g. shop, park, library, hospital",
}

QUESTION_SCHEMA = {
    "type": "object",
    "properties": {
        "questions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "question": {"type": "string"},
                    "correct_answer": {"type": "string"},
                    "wrong_answers": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                },
                "required": ["question", "correct_answer", "wrong_answers"],
            },
        }
    },
    "required": ["questions"],
}

# Letters, spaces and simple punctuation only.
SENTENCE_CHARS = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '.,?!")


class QuestionRequest(BaseModel):
    topic: str = Field(min_length=1, max_length=40)
    count: int = Field(default=10, ge=1, le=10)
    exclude: list[str] = Field(default_factory=list, max_length=50)


class Question(BaseModel):
    question: str
    options: list[str]
    correct_index: int


class QuestionResponse(BaseModel):
    topic: str
    questions: list[Question]


def build_question_prompt(topic: str, count: int, exclude: list[str]) -> str:
    avoid = "; ".join(exclude) or "none"
    example = {
        "questions": [{
            "question": "What is your favourite colour?",
            "correct_answer": "My favourite colour is red.",
            "wrong_answers": ["I am eight years old.", "I go to school by bus."],
        }]
    }

    return f"""
Create {count} different speaking practice questions for children aged 7 to 10 who can answer simple questions in English.

TOPIC: {topic} ({QUESTION_TOPICS[topic]})

RULES:
1. "question" is a short, simple question of 3 to 8 words, ending with "?".
2. "correct_answer" is a full, simple sentence of 3 to 8 words that answers the question.
3. "wrong_answers" are exactly 2 simple sentences that clearly answer a DIFFERENT question.
4. Use easy, child-friendly, everyday words only.
5. No duplicates. Do not ask these questions again: {avoid}.

Reply with JSON only, for example:
{json.dumps(example)}
"""


def is_simple_sentence(text: str, min_words: int, max_words: int) -> bool:
    words = text.split()
    return (
        min_words <= len(words) <= max_words
        and all(ch in SENTENCE_CHARS for ch in text)
        and any(ch.isalpha() for ch in text)
    )


def clean_questions(raw_items, count: int, exclude: list[str]) -> list[Question]:
    """Keep only valid, unique questions and shuffle their answers."""
    seen = {q.strip().lower() for q in exclude}
    cleaned = []

    for item in raw_items:
        if not isinstance(item, dict):
            continue

        question = " ".join(str(item.get("question", "")).split())
        correct = " ".join(str(item.get("correct_answer", "")).split())
        wrong = item.get("wrong_answers")

        if not isinstance(wrong, list) or len(wrong) < 2:
            continue
        wrong = [" ".join(str(w).split()) for w in wrong[:2]]

        if not question.endswith("?") or question.lower() in seen:
            continue
        if not is_simple_sentence(question, 3, 10):
            continue
        if not all(is_simple_sentence(a, 2, 10) for a in [correct, *wrong]):
            continue
        if len({a.lower() for a in [correct, *wrong]}) < 3:
            continue

        options = [correct, *wrong]
        random.shuffle(options)

        seen.add(question.lower())
        cleaned.append(Question(
            question=question,
            options=options,
            correct_index=options.index(correct),
        ))

        if len(cleaned) == count:
            break

    return cleaned


@app.post("/generate-questions", response_model=QuestionResponse)
def generate_questions(request: QuestionRequest):

    topic = request.topic.strip()

    if topic not in QUESTION_TOPICS:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown topic: {request.topic}"
        )

    started = time.time()

    data = ask_llama_json(
        build_question_prompt(topic, request.count, request.exclude),
        QUESTION_SCHEMA,
        num_predict=1700
    )

    try:
        questions = clean_questions(data["questions"], request.count, request.exclude)
    except (KeyError, TypeError):
        questions = []

    if not questions:
        raise HTTPException(
            status_code=502,
            detail="Invalid response from Llama."
        )

    print(f"[generate-questions] {topic}: {len(questions)} questions in {time.time() - started:.1f}s")

    return QuestionResponse(topic=topic, questions=questions)


# ---------------------------------------------------------------
# AI-GENERATED MINIMAL PAIRS (GAME)
# ---------------------------------------------------------------

PAIR_SCHEMA = {
    "type": "object",
    "properties": {
        "pairs": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "word_a": {"type": "string"},
                    "emoji_a": {"type": "string"},
                    "word_b": {"type": "string"},
                    "emoji_b": {"type": "string"},
                },
                "required": ["word_a", "emoji_a", "word_b", "emoji_b"],
            },
        }
    },
    "required": ["pairs"],
}


class PairRequest(BaseModel):
    count: int = Field(default=10, ge=1, le=10)
    exclude: list[str] = Field(default_factory=list, max_length=50)


class PairWord(BaseModel):
    word: str
    emoji: str


class MinimalPair(BaseModel):
    a: PairWord
    b: PairWord


class PairResponse(BaseModel):
    pairs: list[MinimalPair]


def build_pair_prompt(count: int, exclude: list[str]) -> str:
    avoid = ", ".join(w.upper() for w in exclude) or "none"
    example = {"pairs": [{"word_a": "CAT", "emoji_a": "🐱", "word_b": "RAT", "emoji_b": "🐭"}]}

    return f"""
Create {count} different minimal pairs for children aged 4 to 7 who are learning to hear and say sounds.

A minimal pair is two short words that sound almost the same and differ by only ONE sound,
for example CAT and RAT, FAN and VAN, BEAR and PEAR, MOUSE and HOUSE, SOCK and ROCK.

RULES:
1. Both words are real, easy, everyday English nouns a child can picture.
2. Both words change only ONE sound, at the start, middle or end.
3. "emoji_a" and "emoji_b" are ONE emoji each that clearly shows the word. They must be different.
4. Words are in UPPERCASE letters only, 2 to 7 letters, one word each.
5. No duplicates. Do not use these words: {avoid}.

Reply with JSON only, for example:
{json.dumps(example, ensure_ascii=False)}
"""


def is_minimal_pair(a: str, b: str) -> bool:
    """True when the words share most letters and differ in one small part (CAT/RAT, SHIP/SHEEP)."""
    if a == b or abs(len(a) - len(b)) > 1:
        return False

    prefix = 0
    while prefix < min(len(a), len(b)) and a[prefix] == b[prefix]:
        prefix += 1

    suffix = 0
    while (suffix < min(len(a), len(b)) - prefix
           and a[len(a) - 1 - suffix] == b[len(b) - 1 - suffix]):
        suffix += 1

    diff_a = len(a) - prefix - suffix
    diff_b = len(b) - prefix - suffix
    return prefix + suffix >= 2 and 1 <= max(diff_a, diff_b) <= 2


def clean_pairs(raw_items, count: int, exclude: list[str]) -> list[MinimalPair]:
    """Keep only real-looking minimal pairs with two different pictures."""
    seen = {w.strip().upper() for w in exclude}
    cleaned = []

    for item in raw_items:
        if not isinstance(item, dict):
            continue

        a = str(item.get("word_a", "")).strip().upper()
        b = str(item.get("word_b", "")).strip().upper()
        emoji_a = str(item.get("emoji_a", "")).strip()[:8]
        emoji_b = str(item.get("emoji_b", "")).strip()[:8]

        if not all(w.isalpha() and w.isascii() and 2 <= len(w) <= 7 for w in (a, b)):
            continue
        if a in seen or b in seen:
            continue
        if not emoji_a or not emoji_b or emoji_a == emoji_b:
            continue
        if not is_minimal_pair(a, b):
            continue

        seen.update((a, b))
        cleaned.append(MinimalPair(a=PairWord(word=a, emoji=emoji_a), b=PairWord(word=b, emoji=emoji_b)))

        if len(cleaned) == count:
            break

    return cleaned


@app.post("/generate-minimal-pairs", response_model=PairResponse)
def generate_minimal_pairs(request: PairRequest):

    started = time.time()

    data = ask_llama_json(
        build_pair_prompt(request.count, request.exclude),
        PAIR_SCHEMA,
        num_predict=900
    )

    try:
        pairs = clean_pairs(data["pairs"], request.count, request.exclude)
    except (KeyError, TypeError):
        pairs = []

    if not pairs:
        raise HTTPException(
            status_code=502,
            detail="Invalid response from Llama."
        )

    print(f"[generate-minimal-pairs] {len(pairs)} pairs in {time.time() - started:.1f}s")

    return PairResponse(pairs=pairs)
