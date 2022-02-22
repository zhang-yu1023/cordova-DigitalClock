

function tow(n) {
    return n >= 0 && n < 10 ? '0' + n : '' + n;
}

function getcurrentTime() {

    var second = new Date().getSeconds();
    var cardBottom = document.getElementsByClassName('card-bottom')[0];
    var cardInnertop = document.getElementsByClassName('card-innertop')[0];
    var flappings = document.getElementsByClassName('flappings')[0];
   
    var nextsecond=0;
    if(second=='59'){
        nextsecond = tow('0');
    }else{
        nextsecond=tow(second + 1);
    }
    cardBottom.innerText = tow(second);
    flappings.innerText = tow(second);
    cardInnertop.innerText = nextsecond;

    setTimeout(() => {
        flappings.innerText = nextsecond;
        flappings.classList.remove('flapping');
    }, 500)
    setTimeout(() => {
        flappings.classList.add('flapping');
    }, 500)

    flappings.classList.remove('flapping');
}

setInterval(getcurrentTime, 1000);

