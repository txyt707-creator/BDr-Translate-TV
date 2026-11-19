(function(){'use strict';
var sourceList=[],chosen=0,focused=0;
var buttons=['play','source','retry'];
function el(id){return document.getElementById(id)}
function status(s){el('state').textContent=s}
function focus(n){focused=(n+buttons.length)%buttons.length;el(buttons[focused]).focus()}
function showPanel(){document.body.classList.add('showpanel');focus(0)}
function closePanel(){document.body.classList.remove('showpanel');el('play').blur()}
function pickSource(){
 if(!sourceList.length){status('لا توجد مداخل HDMI متاحة');refresh();return}
 if(sourceList.length===1){el('sourceLabel').textContent='الشاشة أبلغت عن HDMI '+sourceList[0].number+' فقط — جارِ فحص المداخل الأخرى';refresh();return}
 chosen=(chosen+1)%sourceList.length;
 updateSourceLabel();
}
function updateSourceLabel(){
 var src=sourceList[chosen];
 if(!src){el('sourceLabel').textContent='لم يتم العثور على HDMI';return}
 el('sourceLabel').textContent='المدخل المحدد: HDMI '+src.number+
  ' • '+(chosen+1)+' من '+sourceList.length+' • اضغط «عرض السوني» للتشغيل';
 status('اخترت HDMI '+src.number)
}
function showHDMI(){
 var src=sourceList[chosen];
 if(!src||!(window.tizen&&tizen.tvwindow)){status('تعذر تحديد مدخل HDMI');el('sourceLabel').textContent='المصدر غير متاح على هذا التلفزيون';return}
 status('جاري عرض HDMI '+src.number+'…');
 // Clear every opaque background *before* requesting BEHIND video compositing.
 document.body.classList.add('live');
 function fail(stage,e){
  var reason=(e&&(e.message||e.name))||'سبب غير معروف';
  document.body.classList.remove('live');
  document.body.classList.add('showpanel');
  el('sourceLabel').textContent='تعذر '+stage+' HDMI '+src.number+': '+reason;
  status('خطأ HDMI: '+reason);
 }
 function success(){
  status('تم تشغيل HDMI '+src.number);
  try{localStorage.setItem('bdr_hdmi',String(src.number))}catch(e){}
  closePanel();
 }
 function runShow(){
  try{tizen.tvwindow.show(success,function(e){fail('عرض صورة',e)},['0%','0%','100%','100%'],'MAIN','BEHIND')}
  catch(e){fail('عرض صورة',e)}
 }
 try{tizen.tvwindow.setSource(src,runShow,function(e){fail('اختيار',e)})}
 catch(e){fail('اختيار',e)}
}
function refresh(){
 if(!(window.tizen&&tizen.systeminfo)){el('sourceLabel').textContent='تجربة معاينة — يحتاج تلفزيون Samsung';return}
 try{tizen.systeminfo.getPropertyValue('VIDEOSOURCE',function(info){
  var all=(info.connected||[]).concat(info.disconnected||[]);
  var seen={};
  sourceList=all.filter(function(s){
   if(s.type!=='HDMI')return false;
   var key=String(s.number);
   if(seen[key])return false;
   seen[key]=true;return true;
  }).sort(function(a,b){return Number(a.number)-Number(b.number)});
  if(!sourceList.length){el('sourceLabel').textContent='لا توجد منافذ HDMI متاحة — شغّل PS5 ثم جرّب مجددًا';return}
  // Prefer the connected HDMI source, or previous working HDMI 2.
  var last='';try{last=localStorage.getItem('bdr_hdmi')||''}catch(e){}
  var match=sourceList.findIndex(function(s){return String(s.number)===last});
  if(match<0)match=sourceList.findIndex(function(s){return s.isConnected});
  chosen=match>=0?match:0;
  updateSourceLabel();
 },function(e){status('خطأ فحص المداخل: '+(e.message||e.name))})}catch(e){status('خطأ: '+e.message)}
}
el('play').onclick=showHDMI;
el('source').onclick=pickSource;
el('retry').onclick=function(){if(window.BDrRelay)window.BDrRelay.retry()};
buttons.forEach(function(id,n){el(id).addEventListener('focus',function(){focused=n})});
document.addEventListener('keydown',function(e){
 var code=e.keyCode,open=document.body.classList.contains('showpanel');
 if(code===10009||code===27){e.preventDefault();if(open)closePanel();else showPanel();return}
 if(!open){if(code===13){e.preventDefault();showPanel()}return}
 if(code===37||code===38){e.preventDefault();focus(focused-1)}
 if(code===39||code===40){e.preventDefault();focus(focused+1)}
 if(code===13){e.preventDefault();el(buttons[focused]).click()}
});
refresh();setTimeout(function(){focus(0)},100);
window.BDrTV={showHDMI:showHDMI,closePanel:closePanel,status:status};
})();