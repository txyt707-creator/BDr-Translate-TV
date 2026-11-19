(function(){'use strict';
var host=document.getElementById('relayHost'), code=document.getElementById('relayCode');
var connect=document.getElementById('relayConnect'), status=document.getElementById('relayStatus');
var last=-1, timer=null, busy=false;
try {host.value=localStorage.getItem('bdr_host')||'';code.value=localStorage.getItem('bdr_code')||'';}catch(e){}
function setStatus(s){status.textContent=s;}
function poll(){
 if(busy)return;
 busy=true;
 var url='http://'+host.value.trim().replace(/^https?:\/\//,'').replace(/\/$/,'').replace(/:\\d+$/,'')+':8765/api/subtitle?pin='+encodeURIComponent(code.value.trim())+'&t='+Date.now();
 fetch(url,{cache:'no-store'}).then(function(r){if(!r.ok)throw Error('HTTP '+r.status);return r.json();})
 .then(function(d){
   setStatus('متصل — انتظار الترجمة');
   if(d.revision!==last){last=d.revision;}
   var subtitle=document.getElementById('subtitle');
   if(d.text){subtitle.textContent='';var span=document.createElement('span');span.textContent=d.text;subtitle.appendChild(span);}
   else{subtitle.textContent='';}
 }).catch(function(e){setStatus('تعذر الاتصال: '+e.message);})
 .then(function(){busy=false;});
}
connect.addEventListener('click',function(){
 if(!/^\d{6}$/.test(code.value.trim()) || !/^[\w.-]+(?::\d+)?$/.test(host.value.trim().replace(/^https?:\/\//,''))){setStatus('اكتب IP الكمبيوتر ورمز 6 أرقام');return;}
 try{localStorage.setItem('bdr_host',host.value.trim());localStorage.setItem('bdr_code',code.value.trim());}catch(e){}
 if(timer)clearInterval(timer);poll();timer=setInterval(poll,850);
 setStatus('جاري الربط...');
});
})();