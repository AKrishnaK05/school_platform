(async()=>{
  try{
    const tryPaths=[
      'C:/nvm4w/nodejs/node_modules/mcp/node_modules/@mintlify/mcp',
      'C:/nvm4w/nodejs/node_modules/@mintlify/mcp',
      'C:/nvm4w/nodejs/node_modules/mcp',
      '@mintlify/mcp'
    ];
    let mod=null, used=null;
    for(const p of tryPaths){
      try{
        mod=require(p);
        used=p;break;
      }catch(e){}
    }
    console.log('moduleLoadedFrom=',used||null);
    if(!mod){
      console.error('Could not require @mintlify/mcp from known locations.');
      process.exit(2);
    }
    console.log('exports:',Object.keys(mod));
    if(mod.fetchMcp) console.log('fetchMcp is function, arity=',mod.fetchMcp.length);
    if(mod.unzipMcp) console.log('unzipMcp is function, arity=',mod.unzipMcp.length);
    if(mod.default) console.log('default export keys:',Object.keys(mod.default||{}));
    // Print source of fetchMcp if available for inspection
    if(mod.fetchMcp) console.log('\nfetchMcp source:\n',mod.fetchMcp.toString().slice(0,2000));
    // Try a cautious call if fetchMcp exists: call with dryRun flag if supported
    if(mod.fetchMcp){
      try{
        console.log('\nAttempting fetchMcp call (may trigger proxy/OAuth)...');
        const result = await mod.fetchMcp({projectId:'18040412930613593715', proxyUrl:'http://localhost:25010', dryRun:true});
        console.log('fetchMcp result (dryRun):', typeof result, result && Object.keys(result).slice(0,50));
      }catch(e){
        console.error('fetchMcp call failed:', e && (e.stack||e.message||e));
      }
    }
  }catch(err){
    console.error('fatal',err && (err.stack||err.message||err));
    process.exit(1);
  }
})();
