var countDown = document.getElementsByClassName('count-down');
var snake = document.getElementsByClassName('snake');
var allbtn = document.getElementsByClassName('all-button');
var btn = document.getElementById('btn');
var body = document.body;

var flag = false;

export function countDownFun(status) {
    // var countDownFun = function (status) {
    if (status == 'disappear') {
        countDown[0].style.display = 'none';
    } else if (status == 'appear') {
        countDown[0].style.display = 'flex';
        // allbtn[0].style.display = 'none';
    }
}

export function snakeFun(status) {
    // var countDownFun = function (status) {
    if (status == 'disappear') {
        snake[0].style.display = 'none';
    } else if (status == 'appear') {
        snake[0].style.display = 'block';
    }
}

// btn.onclick = function () {
//     setTimeout(() => {
//         if (btn.innerText == '启动') {
//             countDown[0].style.display = 'none';
//         }
//         // else if(btn.innerText == '暂停'){
//         //     countDown[0].style.display = 'flex';
//         // }
//     }, 500);

// }
// countDown[0].onclick = function () {
//     flag = !flag;
//     if(flag){
//         countDown[0].style.display = 'none';
//         allbtn[0].style.display = 'block';
//     }else{
//         countDown[0].style.display = 'flex';
//         allbtn[0].style.display = 'none';
//     }
   
// }
