const puppeteer = require('C:\\nvm4w\\nodejs\\node_modules\\mcp\\node_modules\\puppeteer');
const fs = require('fs');
(async()=>{
  const url='https://stitch.withgoogle.com/projects/18040412930613593715';
  const browser=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
  const page=await browser.newPage();
  const logFile='network_log.jsonl';
  if(fs.existsSync(logFile)) fs.unlinkSync(logFile);
  page.on('response', async res=>{
    try{
      const url=res.url();
      const rt=res.request().resourceType();
      if(rt==='xhr' || rt==='fetch' || url.includes('project') || url.includes('mcp') || url.includes('bundle') || url.includes('presigned')|| url.includes('export') || url.includes('googleapis')|| url.includes('stitch')){
        let text='';
        try{ text=await res.text(); }catch(e){ text='[binary or no body]'; }
        fs.appendFileSync(logFile, JSON.stringify({url, status:res.status(), resourceType:rt, bodySnippet:(typeof text==='string'?text.slice(0,2000):String(text))})+"\n");
      }
    }catch(e){ }
  });
  await page.setViewport({width:1280,height:900});
  await page.goto(url,{waitUntil:'networkidle2', timeout:60000});
  // Interact: try to click a few elements to trigger loads
  const sleep=ms=>new Promise(r=>setTimeout(r,ms));
  await page.evaluate(()=>{window.scrollTo(0,document.body.scrollHeight/3)});
  await sleep(1000).catch(()=>{});
  await page.evaluate(()=>{window.scrollTo(0,document.body.scrollHeight*2/3)});
  await sleep(1000).catch(()=>{});
  // Try clicking elements that look like previews
  const selectors=['.thumbnail','[data-screen]','img','a'];
  for(const s of selectors){
    const el=await page.$(s);
    if(el){
      try{ await el.click(); await sleep(800); }catch(e){}
    }
  }
  await sleep(1500);
  await browser.close();
  console.log('Network log saved to', logFile);
})();