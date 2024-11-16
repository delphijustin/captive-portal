const params = new URLSearchParams(window.location.search);
var trys=0;
if(params.has("portaltrys"))
trys=Number(params.get("portaltrys"))+1;
function retryInternet(){
location.href="/portalsuccess/?portaltrys="+trys;
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
location.href="/portalsuccess/?portaltrys=1";
},10000);
});
}
function agreementStart(){
document.getElementById("a").value=agreeID;
}
