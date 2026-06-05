(async()=>{
  try{
    // allow pointing to a local mcp-remote proxy
    process.env.MCP_PROXY_URL = process.env.MCP_PROXY_URL || 'http://localhost:25010/api/v1/public';
    const remote = require('C:/nvm4w/nodejs/node_modules/mcp/node_modules/@mintlify/mcp/bin/remote.js');
    console.log('Loaded fetchMcp/unzipMcp:', !!remote.fetchMcp, !!remote.unzipMcp);
    const projectId = '18040412930613593715';
    console.log('Calling fetchMcp(',projectId,')');
    const res = await remote.fetchMcp(projectId).catch(e=>{ throw e; });
    console.log('fetchMcp result:', JSON.stringify(res).slice(0,2000));
    if(res && res.presignedUrl){
      console.log('Found presignedUrl:', res.presignedUrl);
      // attempt unzip into assets/snitch/mcp
      const dest='C:/Users/adwai/school_platform/parent_app/assets/snitch/mcp_extract';
      const unzip = remote.unzipMcp;
      if(unzip){
        console.log('Attempting to unzip to',dest);
        await unzip(res.presignedUrl,dest,projectId);
        console.log('Unzip complete');
      }
    }
  }catch(err){
    console.error('fetchMcp error:', err && (err.stack||err.message||err));
    process.exit(1);
  }
})();