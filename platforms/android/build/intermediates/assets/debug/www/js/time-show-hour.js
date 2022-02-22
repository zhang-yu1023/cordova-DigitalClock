

function tow(n) {
    return n >= 0 && n < 10 ? '0' + n : '' + n;
}

var hour = new Date().getHours();
var minute = document.getElementsByClassName('flappings-minute')[0];
var rotate = document.getElementsByClassName('rotate')[0];
var flappings = document.getElementsByClassName('flappings-hour')[0];
var cardBottom = document.getElementsByClassName('card-bottom-hour')[0];
var cardTop = document.getElementsByClassName('card-top-hour')[0];
var cardInnertop = document.getElementsByClassName('card-innertop-hour')[0];

// var btn=document.getElementById('btn');

function getcurrentTime() {

    cardTop.classList.remove('rotate-hour');

    flappings.innerText = tow(hour);
    cardBottom.innerText = tow(hour);
    cardInnertop.innerText = tow(hour);

    rotate.addEventListener('webkitAnimationStart', startE, false)
    rotate.addEventListener('animationstart', startE, false)
    rotate.addEventListener('webkitAnimationIteration', startE, false)
    rotate.addEventListener('animationiteration', startE, false)

    //     btn.addEventListener("click",(e)=>{
    //         cardTop.classList.add('rotate-hour');
    //         var rotateM = document.getElementsByClassName('rotate-hour')[0];

    //         console.log('yes',rotateM,);
    //         hour=hour+1;
    //         cardInnertop.innerText = tow(hour)

    //         console.log(111111111);
    //         setTimeout(() => {

    //             flappings.classList.remove('flapping');
    //             console.log(333333);
    //         }, 500);
    //         setTimeout(() => {
    //             flappings.classList.add('flapping');
    //             flappings.innerText = tow(hour)

    //             console.log(2222222);

    //             // cardBottom.innerText = tow(hour);

    //         }, 500)

    //         flappings.classList.remove('flapping');

    //    });

}


function startE() {
    hour = new Date().getHours();
    flappings.classList.remove('flapping');
    var nexthour = 0;
    if (hour == '24') {
        nexthour = tow('0');
    } else {
        nexthour = tow(hour);
    }

    if (minute.innerText == '00' || minute.innerText == '60') {

        cardTop.classList.add('rotate-hour');
        // hour=hour+1;
        cardInnertop.innerText = nexthour;

        setTimeout(() => {
            flappings.classList.remove('flapping');
        }, 500);

        setTimeout(() => {
            flappings.innerText = nexthour;
            flappings.classList.add('flapping');
        }, 500)

    } else {
        cardTop.classList.remove('rotate-hour');
    }

}

getcurrentTime()