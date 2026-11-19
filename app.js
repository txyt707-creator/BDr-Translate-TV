(function () {
'use strict';
var sources=[], sentenceIndex=0, focusIndex=0;
var sentences=['لازم نطلع من هنا قبل ما توصل الشرطة!','انتبه، فيه سيارة ورا المبنى.','يلا بسرعة، الوقت يداهمنا!','هذه ترجمة تجريبية من BDr Translate.'];
var $=function(id){return document.getElementById(id);};
var controls=['sources','refresh','start','hide','relayHost','relayCode','relayConnect'];
function log(message){$('log').textContent=message;$('state').textContent=message;}
function setSentence(){var el=$('subtitle');el.textContent='';var span=document.createElement('span');span.textContent=sentences[sentenceIndex];el.appendChild(span);}
function focusControl(index){focusIndex=(index+controls.length)%controls.length;var el=$(controls[focusIndex]);if(el){el.focus();}}
function showPanel(){document.body.classList.add('showpanel');focusControl(0);}
function refresh(){
 var selector=$('sources');selector.innerHTML='';sources=[];
 if(!(window.tizen&&tizen.systeminfo)){selector.add(new Option('غير متوفر — افتح على Samsung TV',''));log('وضع المعاينة: TVWindow غير متاح');return;}
 try{tizen.systeminfo.getPropertyValue('VIDEOSOURCE',function(info){
  var arr=info.connected||[];sources=arr.filter(function(s){return s.type==='HDMI';});
  if(!sources.length){selector.add(new Option('لا توجد مداخل HDMI متصلة',''));log('لم يتم العثور على HDMI متصل — تأكد من تشغيل PS5');return;}
  sources.forEach(function(s,i){selector.add(new Option('HDMI '+s.number+' ('+(s.isConnected?'متصل':'الحالة غير معروفة')+')',String(i)));});
  selector.selectedIndex=0;
  log('وجدت '+sources.length+' مداخل HDMI — اضغط يمين للانتقال إلى زر العرض، ثم OK');
 },function(e){log('فشل استعلام المداخل: '+(e.message||e.name));});}catch(e){log('تعذر استعلام المصدر: '+e.message);}
}
function showHDMI(){
 var num=$('sources').value,src=sources[Number(num)];
 if(num===''||!src){log('اختر HDMI صالحًا أولًا');return;}
 if(!(window.tizen&&tizen.tvwindow)){log('TVWindow غير متاح');return;}
 try{tizen.tvwindow.setSource(src,function(){
  try{tizen.tvwindow.show(function(){document.body.classList.add('live');document.body.classList.remove('showpanel');log('HDMI نشط — راقب صورة السوني والترجمة');},function(err){log('فشل عرض HDMI: '+(err.message||err.name));},['0%','0%','100%','100%'],'MAIN','BEHIND');}catch(ex){log('خطأ عرض: '+ex.message);}
 },function(err){log('فشل اختيار HDMI: '+(err.message||err.name));});}catch(e){log('خطأ المصدر: '+e.message);}
}
function nextSource(direction){
 var el=$('sources');if(!el.options.length)return;
 el.selectedIndex=(el.selectedIndex+direction+el.options.length)%el.options.length;
 log('المدخل المحدد: '+el.options[el.selectedIndex].text);
}
$('refresh').addEventListener('click',refresh);
$('start').addEventListener('click',showHDMI);
$('hide').addEventListener('click',function(){document.body.classList.remove('showpanel');});
controls.forEach(function(id,i){$(id).addEventListener('focus',function(){focusIndex=i;});});
document.addEventListener('keydown',function(e){
 var key=e.keyCode,open=document.body.classList.contains('showpanel');
 if(e.target && e.target.tagName==='INPUT')return;
 if(key===10009||key===27){e.preventDefault();if(open){document.body.classList.remove('showpanel');}else{showPanel();}return;}
 if(!open){if(key===13){e.preventDefault();showPanel();}else if(key===38||key===40){e.preventDefault();sentenceIndex=(sentenceIndex+(key===38?1:-1)+sentences.length)%sentences.length;setSentence();}return;}
 if(key===37||key===39){e.preventDefault();focusControl(focusIndex+(key===39?1:-1));return;}
 if(key===38||key===40){e.preventDefault();if(focusIndex===0){nextSource(key===40?1:-1);}else{focusControl(focusIndex+(key===40?1:-1));}return;}
 if(key===13){e.preventDefault();if(focusIndex===0){focusControl(2);}else if($(controls[focusIndex]).click){$(controls[focusIndex]).click();}return;}
});
setSentence();showPanel();refresh();
})();
