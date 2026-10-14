const fs = require('fs');
const path = require('path');
const { chromium } = require('/Users/goldilocks/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');

(async () => {
  const browser = await chromium.launch({executablePath:'/Users/goldilocks/Library/Caches/ms-playwright/chromium_headless_shell-1228/chrome-headless-shell-mac-arm64/chrome-headless-shell',headless:true});
  const page = await browser.newPage({viewport:{width:1360,height:1120},deviceScaleFactor:2});
  const failures = [];
  const cases = [];
  const responsive = [];
  page.on('pageerror',e=>failures.push(e.message));
  await page.goto('file://'+path.join(__dirname,'index.html'));
  await page.evaluate(()=>document.fonts.ready);
  for (const screen of ['home','settings']) {
    await page.click('[data-screen="'+screen+'"]');
    for (const theme of ['light','dark']) {
      await page.click('[data-mode="'+theme+'"]');
      for (const variant of ['a','b','c']) {
        await page.click('[data-variant="'+variant+'"]');
        if(screen==='settings')await page.evaluate(()=>{Object.assign(state,{theme:state.mode==='dark'?'night':'paper',font:'Literata',size:3,turn:'Slide',spacing:'Normal',locked:true,tab:'Appearance'});render()});
        for (const width of [390,402]) {
          await page.click('[data-width="'+width+'"]');
          const key = `${screen}-${variant}-${theme}-${width}`;
          const result = await page.evaluate(()=>{
            const phone=document.getElementById('phone');
            const rect=phone.getBoundingClientRect();
            const outside=[...phone.querySelectorAll('button,select,input,.reading-preview,.book-title,.row-title,.setting-label')].filter(el=>{
              const r=el.getBoundingClientRect();
              return r.width&&r.height&&(r.left<rect.left-.5||r.right>rect.right+.5||r.top<rect.top-.5||r.bottom>rect.bottom+.5);
            }).map(el=>el.getAttribute('aria-label')||el.textContent.trim());
            const ctx=document.createElement('canvas').getContext('2d');
            const coverWordFailures=[];
            const coverWordsFit=[...phone.querySelectorAll('.cover-title,.cover-author')].every(el=>{
              const css=getComputedStyle(el);
              if(css.display==='none')return true;
              ctx.font=css.fontWeight+' '+css.fontSize+' '+css.fontFamily;
              const text=css.textTransform==='uppercase'?el.textContent.toUpperCase():el.textContent;
              const widest=Math.max(...text.trim().split(/\s+/).map(word=>ctx.measureText(word).width+(parseFloat(css.letterSpacing)||0)*Math.max(0,word.length-1)));
              const fits=css.hyphens==='none'&&widest<=el.clientWidth+.5;
              if(!fits)coverWordFailures.push({text,size:css.fontSize,width:el.clientWidth,widest,hyphens:css.hyphens});
              return fits;
            });
            return {phoneWidth:rect.width,phoneHeight:rect.height,outside,coverWordsFit,coverWordFailures,fontLoaded:document.fonts.check('17px Literata')};
          });
          cases.push({key,...result});
          if(result.outside.length)failures.push(key+': clipped '+result.outside.join(', '));
          if(!result.coverWordsFit)failures.push(key+': cover word does not fit');
          if(width===390)await page.locator('#phone').screenshot({path:path.join(__dirname,'previews',`${screen}-${variant}-${theme}.png`)});
          if(screen==='settings'&&variant==='b'){
            await page.click('[data-tab="Layout"]');
            await page.click('[data-turn="Scroll"]');
            await page.click('[data-spacing="Loose"]');
            await page.locator('#rotation').uncheck();
            if(width===390)await page.locator('#phone').screenshot({path:path.join(__dirname,'previews',`settings-b-layout-${theme}.png`)});
            await page.click('[data-tab="Appearance"]');
          }
        }
        if(screen==='home')for(const quantity of [1,0]){
          await page.click('[data-quantity="'+quantity+'"]');
          await page.click('[data-width="390"]');
          await page.locator('#phone').screenshot({path:path.join(__dirname,'previews',`home-${variant}-${quantity===1?'one':'empty'}-${theme}.png`)});
          const count=await page.locator('#phone .library .book-button').count();
          cases.push({key:`home-${variant}-${theme}-${quantity===1?'one':'empty'}-390`,expectedBooks:quantity,visibleBooks:count});
          if(count!==quantity)failures.push(`home-${variant}-${theme}: quantity ${quantity}, visible books ${count}`);
        }
        if(screen==='home')await page.click('[data-quantity="4"]');
      }
    }
  }
  await page.click('[data-screen="settings"]');
  await page.click('[data-mode="light"]');
  await page.click('[data-variant="c"]');
  await page.click('[data-theme="sepia"]');
  await page.locator('#font-select').selectOption('Georgia');
  await page.locator('#text-size').fill('5');
  await page.click('[data-spacing="Tight"]');
  const interaction=await page.evaluate(()=>({background:getComputedStyle(document.querySelector('.reading-preview')).backgroundColor,font:getComputedStyle(document.querySelector('.reading-preview')).fontFamily,size:getComputedStyle(document.querySelector('.reading-preview')).fontSize,spacing:document.querySelector('[data-spacing="Tight"]').getAttribute('aria-pressed')}));
  if(interaction.background!=='rgb(239, 227, 203)'||!interaction.font.includes('Georgia')||interaction.size!=='21px'||interaction.spacing!=='true')failures.push('Settings preview did not update');
  await page.click('[data-action="done"]');
  if(await page.locator('.settings-sheet').count())failures.push('Done did not close sheet');
  await page.click('[data-action="reopen"]');
  if(!(await page.locator('.settings-sheet').count()))failures.push('Could not reopen sheet');
  for(const width of [320,390,736]){
    await page.setViewportSize({width,height:1600});
    const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth);
    const phoneFits=await page.evaluate(()=>{const p=document.querySelector('#phone').getBoundingClientRect();const s=document.querySelector('.stage').getBoundingClientRect();return p.left>=s.left-.5&&p.right<=s.right+.5});
    responsive.push({width,overflow,phoneFits});
    if(overflow)failures.push('Gallery horizontal overflow at '+width);
    if(!phoneFits)failures.push('Phone clipped at gallery width '+width);
  }
  await page.setViewportSize({width:1360,height:1120});
  await page.click('[data-screen="home"]');
  await page.click('[data-variant="a"]');
  await page.screenshot({path:path.join(__dirname,'previews','gallery.png'),fullPage:true});
  fs.writeFileSync(path.join(__dirname,'verification.json'),JSON.stringify({cases,responsive,interaction,failures,passed:failures.length===0},null,2)+'\n');
  await browser.close();
  console.log(JSON.stringify({cases:cases.length,failures,interaction},null,2));
  if(failures.length)process.exit(1);
})();
