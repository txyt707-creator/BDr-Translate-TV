(function(){'use strict';
var sourceList=[],chosen=0,focused=0;
var buttons=['play','source','retry'];
function el(id){return document.getElementById(id)}
function status(s){el('state').textContent=s}
function focus(n){focused=(n+buttons.length)%buttons.length;el(buttons[focused]).focus()}
function showPanel(){document.body.classList.add('showpanel');focus(0)}
function closePanel(){document.body.classList.remove('showpanel');el('play').blur()}
function pickSource(){if(!sourceList.length){status('لم يتم العثور على HDMI');return}chosen=(chosen+1)%sourceList.length;el('sourceLabel').textContent='المدخل المحدد: HDMI '+sourceList[chosen].number;showHDMI()}
function showHDMI(){
 var src=sourceList[chosen];
 if(!src||!(window.tizen&&tizen.tvwindow)){status('تعذر تحديد مدخل HDMI');return}
 try{tizen.tvwindow.setSource(src,function(){
  try{tizen.tvwindow.show(function(){document.body.classList.add('live');status('HDMI '+src.number);closePanel()},function(e){status('فشل عرض HDMI: '+(e.message||e.name))},['0%','0%','100%','100%'],'MAIN','BEHIND')}catch(e){status('خطأ العرض: '+e.message)}
 },function(e){status('تعذر تشغيل HDMI: '+(e.message||e.name))})}catch(e){status('خطأ HDMI: '+e.message)}
}
function refresh(){
 if(!(window.tizen&&tizen.systeminfo)){el('sourceLabel').textContent='تجربة معاينة — يحتاج تلفزيون Samsung';return}
 try{tizen.systeminfo.getPropertyValue('VIDEOSOURCE',function(info){
  var all=info.connected||[];
  sourceList=all.filter(function(s){return s.type==='HDMI'});
  if(!sourceList.length){el('sourceLabel').textContent='شغّل PS5 وتأكد من HDMI';return}
  // Prefer the connected HDMI source, or previous working HDMI 2.
  var match=sourceList.findIndex(function(s){return s.isConnected});
  chosen=match>=0?match:0;
  el('sourceLabel').textContent='المدخل المحدد: HDMI '+sourceList[chosen].number;
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