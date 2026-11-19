(function(){'use strict';
var pinNode=document.getElementById('tvPin'),statusNode=document.getElementById('relayStatus'),dot=document.getElementById('dot');
var found='',foundPort=8765,lastRevision=-1,searching=false,active=true,attempt=0,polling=false,watchdog=null;
function pin(){var a=new Uint32Array(1);if(window.crypto&&crypto.getRandomValues){crypto.getRandomValues(a);return ('00000'+(a[0]%1000000)).slice(-6)}return ('00000'+Math.floor(Math.random()*1000000)).slice(-6)}
var currentPin=pin();pinNode.textContent=currentPin;
function message(msg,ok){statusNode.textContent=msg;dot.className='dot'+(ok?' ok':'')}
function networkIP(done){
 try{if(window.webapis&&webapis.network&&webapis.network.getIp){var ip=webapis.network.getIp();if(/^\d+\.\d+\.\d+\.\d+$/.test(ip)){done(ip);return}}}catch(e){}
 if(!(window.tizen&&tizen.systeminfo)){done('');return}
 var called=false;
 function finish(ip){if(!called){called=true;done(ip||'')}}
 try{tizen.systeminfo.getPropertyValue('WIFI_NETWORK',function(x){if(x.ipAddress){finish(x.ipAddress)}else{ethernet()}},ethernet)}catch(e){ethernet()}
 function ethernet(){try{tizen.systeminfo.getPropertyValue('ETHERNET_NETWORK',function(x){finish(x.ipAddress)},function(){finish('')})}catch(e){finish('')}}
}
function check(ip,timeout,callback,port){
 port=port||8765;
 var xhr=new XMLHttpRequest(),ended=false;
 function finish(obj){if(ended)return;ended=true;callback(obj)}
 xhr.open('GET','http://'+ip+':'+port+'/api/subtitle?pin='+currentPin+'&t='+Date.now(),true);
 xhr.timeout=timeout;
 xhr.onreadystatechange=function(){if(xhr.readyState===4){if(xhr.status===200){try{finish(JSON.parse(xhr.responseText))}catch(e){finish(null)}}else finish(null)}};
 xhr.onerror=function(){finish(null)};xhr.ontimeout=function(){finish(null)};
 try{xhr.send()}catch(e){finish(null)}
}
function setText(d){
 if(d.revision===lastRevision)return;lastRevision=d.revision;
 var sub=document.getElementById('subtitle');sub.textContent='';
 if(d.text){var span=document.createElement('span');span.textContent=String(d.text).slice(0,300);sub.appendChild(span)}
}
function listen(ip,port){
 foundPort=port||8765;
 if(!active)return;
 found=ip;try{localStorage.setItem('bdr_last_phone',ip)}catch(e){}
 message('تم الربط بالآيفون',true);
 if(window.BDrTV){window.BDrTV.status('متصل بالآيفون');}
 function poll(){
  if(!found||polling)return;polling=true;
  check(found,900,function(d){
   polling=false;if(d&&typeof d.revision==='number'){setText(d);message('متصل — الترجمة جاهزة',true)}
   else{found='';lastRevision=-1;message('انقطع الاتصال، جاري إعادة البحث…',false);scheduleScan()}
  },foundPort);
 }
 if(watchdog)clearInterval(watchdog);
 watchdog=setInterval(poll,400);poll();
}
function scheduleScan(){if(!active||searching||found)return;setTimeout(scan,1600)}
function scan(){
 if(searching||found||!active)return;
 searching=true;attempt++;message('جاري العثور على الآيفون تلقائيًا…',false);
 networkIP(function(tvIP){
  var match=/^(\d+\.\d+\.\d+)\.\d+$/.exec(tvIP||'');
  // Typical home /24 networks; network prefix is taken from TV when possible.
  var prefix=match?match[1]:'192.168.0';
  var candidates=[],used={};
  function add(x){if(x&&!used[x]&&x!==tvIP){used[x]=1;candidates.push(x)}}
  try{var saved=localStorage.getItem('bdr_last_phone');if(saved)add(saved)}catch(e){}
  for(var n=2;n<255;n++)add(prefix+'.'+n);
  var cursor=0,inFlight=0,finished=false;
  function complete(ip,d,port){
   inFlight--;
   if(finished)return;
   if(d&&typeof d.revision==='number'){finished=true;searching=false;listen(ip,port);return}
   launch()
  }
  function launch(){
   if(finished)return;
   while(inFlight<20&&cursor<candidates.length){
    (function(ip){inFlight++;check(ip,650,function(d){
      if(d){complete(ip,d,8765)}
      else check(ip,650,function(ext){complete(ip,ext,8766)},8766)
    })})(candidates[cursor++])
   }
   if(!inFlight&&cursor>=candidates.length){
    searching=false;message('بانتظار الآيفون — افتح التطبيق واكتب الرمز',false);scheduleScan()
   }
  }
  launch()
 })
}
window.BDrRelay={retry:function(){if(watchdog){clearInterval(watchdog);watchdog=null}found='';lastRevision=-1;searching=false;scan()}};
scan();
})();