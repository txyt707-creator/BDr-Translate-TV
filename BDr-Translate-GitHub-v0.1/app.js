(function () {
'use strict';
var sources=[], idx=0;
var sentences=['لازم نطلع من هنا قبل ما توصل الشرطة!','انتبه، فيه سيارة ورا المبنى.','يلا بسرعة، الوقت يداهمنا!','هذه ترجمة تجريبية من BDr Translate.'];
var $=function(id){return document.getElementById(id);};
var log=function(s){$('log').textContent=s;$('state').textContent=s;};
function setSentence(){ $('subtitle').innerHTML=''; var span=document.createElement('span');span.textContent=sentences[idx];$('subtitle').appendChild(span); }
function refresh(){
 var selector=$('sources'); selector.innerHTML=''; sources=[];
 if(!(window.tizen&&tizen.systeminfo)){ selector.add(new Option('غير متوفر — افتح على Samsung TV','')); log('وضع المعاينة: TVWindow غير متاح');return;}
 try{tizen.systeminfo.getPropertyValue('VIDEOSOURCE',function(info){
  var arr=info.connected||[]; sources=arr.filter(function(s){return s.type==='HDMI';});
  if(!sources.length){selector.add(new Option('لا توجد مداخل HDMI متصلة',''));log('لم يتم العثور على HDMI متصل — تأكد من تشغيل PS5');return;}
  sources.forEach(function(s,i){selector.add(new Option('HDMI '+s.number+' ('+(s.isConnected?'متصل':'الحالة غير معروفة')+')',String(i)));});
  log('وجدت '+sources.length+' مداخل HDMI — اختر مدخل PS5');
 },function(e){log('فشل استعلام المداخل: '+(e.message||e.name));});}catch(e){log('تعذر استعلام المصدر: '+e.message);}
}
function showHDMI(){
 var num=$('sources').value, src=sources[Number(num)];
 if(num===''||!src){log('اختر HDMI صالحًا أولًا');return;}
 if(!(window.tizen&&tizen.tvwindow)){log('TVWindow غير متاح');return;}
 try{tizen.tvwindow.setSource(src,function(){
  try{tizen.tvwindow.show(function(){document.body.className='live';log('HDMI نشط — راقب صورة السوني والترجمة');},function(err){log('فشل عرض HDMI: '+(err.message||err.name));},['0%','0%','100%','100%'],'MAIN','BEHIND');}catch(ex){log('خطأ عرض: '+ex.message);}
 },function(err){log('فشل اختيار HDMI: '+(err.message||err.name));});}catch(e){log('خطأ المصدر: '+e.message);}
}
$('refresh').addEventListener('click',refresh);$('start').addEventListener('click',showHDMI);$('hide').addEventListener('click',function(){document.body.classList.remove('showpanel');});
document.addEventListener('keydown',function(e){var key=e.keyCode;
 if(key===13){document.body.classList.toggle('showpanel');}
 if(key===38||key===40){idx=(idx+(key===38?1:-1)+sentences.length)%sentences.length;setSentence();}
 if(key===10009||key===27){try{tizen.application.getCurrentApplication().exit();}catch(ex){document.body.classList.add('showpanel');}}
});
setSentence();document.body.classList.add('showpanel');refresh();
})();
