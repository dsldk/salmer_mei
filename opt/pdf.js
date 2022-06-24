// Create PDF from a web page with Node.js and Puppeteer
// Usage:
// node pdf [filename] [url]
// Example:
// node pdf dsl.pdf https://salmer.dsl.dk/thomissoen_1569/2/2

 

const puppeteer = require('puppeteer');

// command line arguments passed to node: 'node', [name_ of this script], [arg1], [arg2], ...
const args = process.argv;
// use file name 'dsl.pdf' if no file name is passed
const filename = args[2]? args[2] : 'dsl.pdf';
const url = args[3]? args[3] : '';

// delay function
function sleep(millis) {
  return new Promise(resolve => setTimeout(resolve, millis));
}
 

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  // declare html markup for header
  const head = '<div style="font-size: 6pt; padding-top: 2mm; padding-left: 15mm; text-align: left; width: 100%;"><span>Det Danske Sprog- og Litteraturselskab</span></div>';

  console.log('Writing '+url+' to '+filename);

  // Wait for web site to load
  await page.goto(url, {
    waitUntil: 'load',
  // or consider:   
  // waitUntil: 'networkidle0'
  });

 

  // Just to be sure, wait for another second
  await sleep(1000);

 

  // Generate PDF
  const pdf = await page.pdf({
    path: filename,
    format: 'a4',
    margin: {
      top: '20mm',
      right: '15mm',
      left: '15mm',
      bottom: '20mm'
    },
    displayHeaderFooter: true,
    headerTemplate: head   
  });

 

  await browser.close();
  return pdf

})();
