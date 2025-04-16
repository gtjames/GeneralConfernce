import os
import re
from bs4 import BeautifulSoup
from collections import Counter
from collections import defaultdict

# Set of English stop words
stopWords = set([
    "the","of","and","to","in","a","that","we","for","our","i","is",
    "his","you","as","with","he","on","be","this","are","not","it",
    "have","by","was","but","or","an","at","from","they","them","if",
    "so","do","will","my","me","their","there","has","had","who","when",
    "what","which","would","should","can","could","how","all","about","more",
    "s","m","your","may","t","unto","r","b","h","w","e","day","also","those",
    "before","were","know","young","l","d","like", "http","https"
])


def extractWordsFromHTML(filePath):
    print(f"Processing file: {filePath}")
    with open(filePath, "r", encoding="utf-8") as f:
        html = f.read()
    soup = BeautifulSoup(html, "html.parser")
    body_block = soup.select_one(".body-block")
    text = body_block.get_text() if body_block else ""
    words = re.findall(r"\b[a-zA-Z]+\b", text.lower())
    return [word for word in words if word not in stopWords]

# Initialize counters
allWords = Counter()                # Counter for all words
folder = "talks"

# Loop through all .html files in current directory
for filename in os.listdir(folder):
    if filename.endswith(".html"):
        filePath = os.path.join(folder, filename)
        words = extractWordsFromHTML(filePath)
        allWords.update(words)


# Sort and get top 200
top20 = allWords.most_common(200)

# Save to file
with open("top_words.txt", "w", encoding="utf-8") as out:
    for word, count in top20:
        out.write(f"{word}: {count}\n")

print("✅ Top 200 words saved to top_words.txt")
