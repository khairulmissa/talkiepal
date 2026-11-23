import os
import re
import threading
from itertools import product

import numpy as np

PHONEME_MODEL = os.getenv("PHONEME_MODEL", "facebook/wav2vec2-lv-60-espeak-cv-ft")
SAMPLE_RATE = 16000
PERFECT_FROM = 0.9
MAX_PRONUNCIATIONS = 32
MISTAKE_PENALTY = 35
SHORT_WORD_PHONES = 6
FINAL_STOPS = {"T", "D", "K", "P", "B", "G"}

VOWELS = {"AA", "AE", "AH", "AO", "AW", "AY", "EH", "ER", "EY", "IH", "IY", "OW", "OY", "UH", "UW"}

CLOSE_VOWELS = [
    {"IH", "IY"},
    {"UH", "UW"},
    {"AH", "AA", "AO"},
    {"AH", "ER"},
    {"AH", "IH"},
    {"EH", "AE"},
    {"EH", "EY"},
    {"OW", "AO"},
]

VOICING_PAIRS = [
    {"T", "D"},
    {"P", "B"},
    {"K", "G"},
    {"S", "Z"},
    {"F", "V"},
    {"SH", "ZH"},
    {"CH", "JH"},
]

EASY_PAIRS = [{"TH", "DH"}, {"N", "NG"}]

IPA_TO_ARPA = {
    "tʃ": ["CH"], "dʒ": ["JH"], "t͡ʃ": ["CH"], "d͡ʒ": ["JH"],
    "aɪ": ["AY"], "aʊ": ["AW"], "eɪ": ["EY"], "oʊ": ["OW"], "əʊ": ["OW"], "ɔɪ": ["OY"],
    "iː": ["IY"], "uː": ["UW"], "ɑː": ["AA"], "ɔː": ["AO"], "ɜː": ["ER"],
    "ɪə": ["IH", "AH"], "eə": ["EH", "AH"], "ʊə": ["UH", "AH"],
    "n̩": ["N"], "l̩": ["L"], "m̩": ["M"],
    "i": ["IY"], "u": ["UW"], "ɑ": ["AA"], "ɔ": ["AO"], "æ": ["AE"], "ʌ": ["AH"], "ɐ": ["AH"],
    "ə": ["AH"], "ɛ": ["EH"], "e": ["EH"], "ɜ": ["ER"], "ɝ": ["ER"], "ɚ": ["ER"],
    "ɪ": ["IH"], "ᵻ": ["IH"], "ʊ": ["UH"], "o": ["OW"], "a": ["AA"], "ɒ": ["AA"],
    "p": ["P"], "b": ["B"], "t": ["T"], "d": ["D"], "k": ["K"], "g": ["G"], "ɡ": ["G"],
    "f": ["F"], "v": ["V"], "θ": ["TH"], "ð": ["DH"], "s": ["S"], "z": ["Z"],
    "ʃ": ["SH"], "ʒ": ["ZH"], "h": ["HH"], "m": ["M"], "n": ["N"], "ŋ": ["NG"],
    "l": ["L"], "ɫ": ["L"], "ɹ": ["R"], "r": ["R"], "ɾ": ["T"], "w": ["W"], "j": ["Y"],
    "x": ["HH"], "ç": ["HH"], "χ": ["HH"], "ʔ": [],
    "ʁ": ["GH"], "ɣ": ["GH"], "ʀ": ["GH"], "ɢ": ["G"], "q": ["K"], "β": ["V"], "ʋ": ["V"],
}


FRIENDLY = {
    "TH": "TH", "DH": "TH", "SH": "SH", "ZH": "ZH", "CH": "CH", "JH": "J",
    "NG": "NG", "HH": "H", "Y": "Y",
}

_IPA_KEYS = sorted(IPA_TO_ARPA, key=len, reverse=True)

_model = None
_processor = None
_load_error = None
_load_lock = threading.Lock()
_run_lock = threading.Lock()
_cmu = None


def friendly(phone):
    if phone is None:
        return None
    return FRIENDLY.get(phone, phone)


def is_vowel(phone):
    return phone in VOWELS


def _in_pairs(a, b, pairs):
    return any(a in pair and b in pair for pair in pairs)


def substitution_cost(expected, heard):
    if expected == heard:
        return 0.0
    if is_vowel(expected) and is_vowel(heard):
        return 0.25 if _in_pairs(expected, heard, CLOSE_VOWELS) else 0.6
    if _in_pairs(expected, heard, EASY_PAIRS):
        return 0.25
    if _in_pairs(expected, heard, VOICING_PAIRS):
        return 0.5
    return 1.0


def deletion_cost(expected, last=False):
    if is_vowel(expected):
        return 0.6
    if last and expected in FINAL_STOPS:
        return 0.4
    return 1.0


def insertion_cost(heard):
    return 0.3 if is_vowel(heard) else 0.5


def cmu():
    global _cmu
    if _cmu is None:
        import cmudict

        _cmu = cmudict.dict()
    return _cmu


def words_of(text):
    return [w for w in re.sub(r"[^a-z' ]", " ", text.lower()).split() if w.strip("'")]


def expected_options(target):
    words = words_of(target)
    if not words:
        return []

    per_word = []
    for word in words:
        prons = cmu().get(word) or cmu().get(word.replace("'", ""))
        if not prons:
            return []
        unique = []
        for pron in prons:
            phones = [re.sub(r"\d", "", p) for p in pron]
            if phones not in unique:
                unique.append(phones)
        per_word.append(unique)

    options = []
    for combo in product(*per_word):
        options.append([p for phones in combo for p in phones])
        if len(options) >= MAX_PRONUNCIATIONS:
            break
    return options


def ipa_to_arpa(ipa_text):
    phones = []
    for token in ipa_text.split():
        i = 0
        while i < len(token):
            for key in _IPA_KEYS:
                if token.startswith(key, i):
                    phones.extend(IPA_TO_ARPA[key])
                    i += len(key)
                    break
            else:
                i += 1
    return phones


def align(expected, heard):
    n, m = len(expected), len(heard)
    cost = np.zeros((n + 1, m + 1))
    move = np.zeros((n + 1, m + 1), dtype=np.int8)

    for i in range(1, n + 1):
        cost[i][0] = cost[i - 1][0] + deletion_cost(expected[i - 1], i == n)
        move[i][0] = 1
    for j in range(1, m + 1):
        cost[0][j] = 0.0
        move[0][j] = 2

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            inside = i < n
            choices = [
                (cost[i - 1][j - 1] + substitution_cost(expected[i - 1], heard[j - 1]), 0),
                (cost[i - 1][j] + deletion_cost(expected[i - 1], i == n), 1),
                (cost[i][j - 1] + (insertion_cost(heard[j - 1]) if inside else 0.0), 2),
            ]
            best = min(choices, key=lambda c: c[0])
            cost[i][j], move[i][j] = best

    end = int(np.argmin(cost[n])) if m else 0
    total = float(cost[n][end])

    detail = []
    i, j = n, end
    while i > 0:
        step = move[i][j] if j > 0 else 1
        if step == 0:
            detail.append((expected[i - 1], heard[j - 1]))
            i -= 1
            j -= 1
        elif step == 1:
            detail.append((expected[i - 1], None))
            i -= 1
        else:
            j -= 1
    detail.reverse()
    return total, detail


def load_model():
    global _model, _processor, _load_error
    if _model is not None or _load_error is not None:
        return _model
    with _load_lock:
        if _model is None and _load_error is None:
            try:
                import torch
                from transformers import (
                    Wav2Vec2FeatureExtractor,
                    Wav2Vec2ForCTC,
                    Wav2Vec2PhonemeCTCTokenizer,
                )

                tokenizer = Wav2Vec2PhonemeCTCTokenizer.from_pretrained(PHONEME_MODEL, do_phonemize=False)
                extractor = Wav2Vec2FeatureExtractor.from_pretrained(PHONEME_MODEL)
                model = Wav2Vec2ForCTC.from_pretrained(PHONEME_MODEL)
                model.eval()
                torch.set_grad_enabled(False)
                cmu()
                _processor = (extractor, tokenizer)
                _model = model
            except Exception as error:
                _load_error = str(error)
    return _model


def load_in_background():
    def load():
        load_model()
        if _model is not None:
            print(f"PHONEME READY: {PHONEME_MODEL}", flush=True)
        else:
            print(f"PHONEME SCORING OFF: {_load_error}", flush=True)

    threading.Thread(target=load, daemon=True).start()


def is_ready():
    return _model is not None


def recognise_phonemes(audio):
    import torch

    model = load_model()
    if model is None:
        return None
    extractor, tokenizer = _processor
    with _run_lock:
        inputs = extractor(audio, sampling_rate=SAMPLE_RATE, return_tensors="pt")
        with torch.no_grad():
            logits = model(inputs.input_values).logits
        ids = torch.argmax(logits, dim=-1)
        text = tokenizer.batch_decode(ids)[0]
    return text


def score_phones(expected_list, heard):
    best = None
    for expected in expected_list:
        total, detail = align(expected, heard)
        similarity = max(0.0, 1.0 - total / max(len(expected), 1))
        if best is None or similarity > best[0]:
            best = (similarity, expected, detail)
    return best


def consonant_errors(detail):
    errors = []
    for index, (expected, heard) in enumerate(detail):
        if is_vowel(expected):
            continue
        if heard is None:
            if index == len(detail) - 1 and expected in FINAL_STOPS:
                continue
            errors.append((expected, heard))
        elif substitution_cost(expected, heard) >= 1.0:
            errors.append((expected, heard))
    return errors


def to_score(similarity, expected, detail):
    errors = len(consonant_errors(detail))
    penalty = MISTAKE_PENALTY * min(1.0, SHORT_WORD_PHONES / max(len(expected), 1))
    by_errors = 100 - penalty * errors
    if similarity >= PERFECT_FROM:
        by_similarity = 100
    else:
        by_similarity = (similarity / PERFECT_FROM) ** 2 * 100
    return int(round(max(0.0, min(by_similarity, by_errors))))


def mistakes_from(detail):
    found = []
    for expected, heard in consonant_errors(detail):
        item = {"expected": friendly(expected), "heard": friendly(heard)}
        if item not in found:
            found.append(item)
    found.sort(key=lambda m: m["heard"] is None)
    return found


def assess(audio, target):
    expected_list = expected_options(target)
    if not expected_list:
        return None

    ipa = recognise_phonemes(audio)
    if ipa is None:
        return None

    heard = ipa_to_arpa(ipa)
    if not heard:
        return {
            "score": 0,
            "expected": expected_list[0],
            "heard": [],
            "ipa": ipa,
            "mistakes": [],
        }

    similarity, expected, detail = score_phones(expected_list, heard)
    return {
        "score": to_score(similarity, expected, detail),
        "expected": expected,
        "heard": heard,
        "ipa": ipa,
        "mistakes": mistakes_from(detail),
    }