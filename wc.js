const fs = require('fs');
const path = require('path');
const cheerio = require('cheerio'); // Similar to BeautifulSoup

// Set of English stop words
const stopWords = new Set([
  'the','of','and','to','in','a','that','we','for','our','i','is',
  'his','you','as','with','he','on','be','this','are','not','it',
  'have','by','was','but','or','an','at','from','they','them','if',
  'so','do','will','my','me','their','there','has','had','who','when',
  'what','which','would','should','can','could','how','all','about','more',
  's','m','your','may','t','unto','r','b','h', 'w', 'e', 'day','also','those',
  'before','were','know','young','l','d','like', 'http','https'
]);

function extractWordsFromHTML(filePath) {
  console.log(`Processing file: ${filePath}`);
  const html = fs.readFileSync(filePath, 'utf-8');
  const $ = cheerio.load(html);
  // const header = $('body').text();
  const text = $('.body-block').text();
  const words = text
    .toLowerCase()
    .match(/\b[a-zA-Z]+\b/g) || [];
  return words.filter(word => !stopWords.has(word));
}

// Word counter
const wordCounts = {};

const folder = 'talks';
fs.readdirSync(folder).forEach(file => {
  if (file.endsWith('.html')) {
    const filePath = path.join(folder, file);
    const words = extractWordsFromHTML(filePath);
    words.forEach(word => {
      wordCounts[word] = (wordCounts[word] || 0) + 1;
    });
  }
});

// Sort and get top 200
const topWords = Object.entries(wordCounts)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 200);

// Write to file
const output = topWords.map(([word, count]) => `${word}: ${count}`).join('\n');
fs.writeFileSync('top_words.txt', output, 'utf-8');

console.log('✅ Top 2000 words saved to top_words.txt');
