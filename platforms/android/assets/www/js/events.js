import { countDownFun } from './module-status.js'
import { snakeFun } from './module-status.js'


/**
 *  deviceready 设备api调用时，调用
 *  参数1：事件名
 *  参数2：回调函数
 *  参数3：是否在捕获阶段执行，默认flase(冒泡阶段执行)
 * 
**/
document.addEventListener("deviceready", onDeviceReady, false);
var received = document.getElementsByClassName('received');
var app = document.getElementsByClassName('app');


// device APIs are available
function onDeviceReady() {
    console.log('页面加载完毕，可以开始啦')
    console.log('Running cordova-' + cordova.platformId + '@' + cordova.version);


    // //初始阶段默认加载项  --> 初始页面消失
    // received[0].style.display = 'block';
    // countDownFun('disappear')
    // window.setTimeout(function () {
    //     // // listening[0].style.display = 'none';
      
    //     received[0].style.display = 'none';
    // }, 5000)


    //倒计时模块启动
    window.setTimeout(function () {
        app[0].style.display = 'none';
        countDownFun('appear')
    }, 2000)

    //snake 



    //设备api
    document.addEventListener("pause", onPause, false);
    document.addEventListener("resume", onResume, false);
    document.addEventListener("menubutton", onMenuKeyDown, false);
    window.addEventListener("batterystatus", onBatteryStatus, false);
    window.addEventListener("batterylow", onBatteryLow, false);

    // 点击事件确认坐标位置
    // body.addEventListener('click', function (x) {
    //     console.log(`%c(${x.clientX},${x.clientY})`, 'color:red')
    //     log(`(${x.clientX},${x.clientY})`)
    // })

}


function onPause() {
    app[0].style.display = 'block';
    countDownFun('disappear')
    console.log('暂时退出')
}

function onResume() {
    app[0].style.display = 'none';
    countDownFun('appear')
    console.log('欢迎回来')
}

function onMenuKeyDown() {

}

function onBatteryStatus(status) {
    console.log('电量:' + status.level + " %,是否正在充电:" + status.isPlugged)
    console.log("Level: " + status.level + " isPlugged: " + status.isPlugged);
}
function onBatteryLow(status) {
    console.log("电量:" + status.level + "%,电量低，请充电")
    console.log('电量低，请充电')
}


function log(msg) {
    var p = document.createElement("p");
    p.style.fontSize = '20px';
    p.style.color = 'blue';
    p.innerHTML = msg;

    var status = document.getElementsByClassName('status');
    status[0].style.position = 'absolute';
    status[0].style.top = '0px';
    status[0].appendChild(p)

    document.body.appendChild(p)
}