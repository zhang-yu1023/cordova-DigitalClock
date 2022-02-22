


var oSpan = document.getElementsByClassName('current')[0];
var btn = document.getElementById('btn');

// function getDate() {

//     var oldTime = new Date().getTime();//现在距离1970年的毫秒数

//     var newDate = new Date('2022/3/1 00:00:00');
//     var newTime = newDate.getTime();//2022/2/1年距离1970年的毫秒数

//     var allseconds = Math.floor(newTime - oldTime);

//     var day = Math.floor(allseconds / 1000 / 60 / 60 / 24);
//     var hour = Math.floor(allseconds / 1000 / 60 / 60 % 24);
//     var minute = Math.floor(allseconds / 1000 / 60 % 60);
//     var second = Math.floor(allseconds / 1000 % 60);

//     var str = tow(day) + '<span class="time">天</span>'
//         + tow(hour) + '<span class="time">时</span>'
//         + tow(minute) + '<span class="time">分</span>'
//         + tow(second) + '<span class="time">秒</span>';
//     oSpan.innerHTML = str;
// }
function tow(n) {
    return n >= 0 && n < 10 ? '0' + n : '' + n;
}


// getDate();
function getcurrentTime() {
    // var currentTime=

    // var hour = 24 - new Date().getHours();
    // var minute = 60 - new Date().getMinutes();
    var second = new Date().getSeconds();
    // console.log(new Date(), hour, minute, second);

    var str = '<div class="animation-time-up"><div class="animation-time-upchild">' + tow(second) + '</div></div>'
        + '<div class="animation-time-down">' + tow(second) + '</div>';

    // var str = '<div class="animation-time">' + tow(hour) + '</div>' + '<span class="time">时</span>'+
    // '<div class="animation-time">'  + tow(minute) + '</div>' + '<span class="time">分</span>'+
    // '<div class="animation-time">'  + tow(second) + '</div>' + '<span class="time">秒</span>';

    oSpan.innerHTML = str;

    // var animationTimeUp = document.getElementsByClassName('animation-time-up')[0];
    var animationTimeUpChild = document.getElementsByClassName('animation-time-upchild')[0];
    // animationTimeUpChild.classList.add('roate')

    animationTimeUpChild.addEventListener('animationstart', (e) => {
        var animationMiddle = '<div class="animation-time-middle">' + tow(second + 1) + '</div>'
        $(oSpan).append(animationMiddle)

        setTimeout(() => {
            animationTimeUpChild.innerHTML = tow(second + 1);
            animationTimeUpChild.classList.add('flapping')

        }, 500);

    }, false)
}

setInterval(getcurrentTime, 1000);
// getcurrentTime()


// something waiting for resolution
//1.css 伴随动画的perspective（应该应用于父元素，但是会导致翻转效果覆盖整个画面）效果（可能会改动到整体布局）