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
