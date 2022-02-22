

function tow(n) {
    return n >= 0 && n < 10 ? '0' + n : '' + n;
}

var minute = new Date().getMinutes();
var second = document.getElementsByClassName('flappings')[0];
var rotate = document.getElementsByClassName('rotate')[0];
var flappings = document.getElementsByClassName('flappings-minute')[0];
var cardBottom = document.getElementsByClassName('card-bottom-minute')[0];
var cardTop = document.getElementsByClassName('card-top-minute')[0];
var cardInnertop = document.getElementsByClassName('card-innertop-minute')[0];

var btn=document.getElementById('btn');

function getcurrentTime() {
    
    cardTop.classList.remove('rotate-minute');

    flappings.innerText = tow(minute);
    cardBottom.innerText = tow(minute);
    cardInnertop.innerText = tow(minute);
      
    rotate.addEventListener('webkitAnimationStart', startE, false)
    rotate.addEventListener('animationstart', startE, false)
    rotate.addEventListener('webkitAnimationIteration', startE, false)
    rotate.addEventListener('animationiteration', startE, false)

}

function startE(){
    minute = new Date().getMinutes();
    flappings.classList.remove('flapping');

    if(second.innerText=='00'|| second.innerText=='60'){
        var nextminute=0;
        if(minute=='59'){
            nextminute = tow('0');
        }else{
            nextminute=tow(minute);
        }


        cardTop.classList.add('rotate-minute');
        // minute=minute+1;
        cardInnertop.innerText = nextminute;

        setTimeout(() => {
            flappings.classList.remove('flapping');
        }, 500);
        setTimeout(() => {
            flappings.innerText = nextminute;
            cardBottom.innerText = nextminute;
            flappings.classList.add('flapping');
        }, 500)
   
     }else{
        cardTop.classList.remove('rotate-minute');
     }
}

getcurrentTime()