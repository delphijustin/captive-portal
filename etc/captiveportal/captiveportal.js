const params = new URLSearchParams(window.location.search);
var trys=Number(params.get("portalsuccess"))+1;
function retryInternet(){
location.href="/portalsuccess/?portalsuccess="+trys;
}
function blockedPageStart(){
if(games.length==0){
document.getElementById("nogames").style.display="block";
}
games.forEach(function(game){
document.getElementById("games").innerHTML+='<li><a href="//'+portalip+'/games/'+game.filename+'">'+game.caption+'</a></li>';
});
}
function login(form){
document.getElementById("error").innerHTML="Please wait...";
$.get("/portallogin/"+form.u.value.toLowerCase()+"/"+form.p.value,
function(results){
document.getElementById("error").innerHTML=results;
if(results.indexOf("Welcome")>0)setTimeout(function(){
location.href="/portalsuccess/?portalsuccess=1";
},10000);
});
}
function agree(o){
if(o.value!="I Agree")return;
location.href="/portallogin/agree/"+agreeID;
}
