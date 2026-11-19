(function(){'use strict';
var host=document.getElementById('relayHost'), code=document.getElementById('relayCode');
var connect=document.getElementById('relayConnect'), status=document.getElementById('relayStatus'), pinText=document.getElementById('tvPin');
var last=-1, timer=null, busy=false;
function generatePin() {
 var bytes=new Uint32Array(1);
 if(window.crypto&&window.crypto.getRandomValues){window.crypto.getRandomValues(bytes);return String(bytes[0]%1000000).padStart(6,'0');}
 return String(Math.floor(Math.random()*1000000)).padStart(6,'0'); // prototype only
}
code.value=generatePin();pinText.textContent=code.value;
try{host.value=localStorage.getItem('bdr_phone_ip')||'';}catch(e){}
function setStatus(s){status.textContent=s;}
function poll(){
 if(busy)return;busy=true;
 var raw=host.value.trim().replace(/^https?:\/\//,'').replace(/\/$/,'').replace(/:\d+$/,'');
 var url='http://'+raw+':8765/api/subtitle?pin='+encodeURIComponent(code.value)+'&t='+Date.now();
 fetch(url,{cache:'no-store'}).then(function(r){if(!r.ok)throw Error('HTTP '+r.status);return r.json();})
 .then(function(d){
  setStatus('متصل بالآيفون — استقبال الترجمة');
  if(d.revision!==last){last=d.revision;var subtitle=document.getElementById('subtitle');subtitle.textContent='';if(d.text){var span=document.createElement('span');span.textContent=d.text;subtitle.appendChild(span);}}
 }).catch(function(e){setStatus('تعذر الاتصال: '+e.message);})
 .then(function(){busy=false;});
}
connect.addEventListener('click',function(){
 if(!/^(\d{1,3}\.){3}\d{1,3}$/.test(host.value.trim())){setStatus('أدخل IP الآيفون مثل 192.168.0.50');return;}
 try{localStorage.setItem('bdr_phone_ip',host.value.trim());}catch(e){}
 if(timer)clearInterval(timer);last=-1;poll();timer=setInterval(poll,350);setStatus('جاري الاتصال بالآيفون...');
});
})();