var body = document.body;
var flag = false;
var direction = 'left';



var btn = document.getElementById('btn');
var btn_top = document.getElementById('btn-top');
var btn_bottom = document.getElementById('btn-bottom');
var btn_left = document.getElementById('btn-left');
var btn_right = document.getElementById('btn-right');


btn_top.onclick = function () { direction = 'top'; }
btn_bottom.onclick = function () { direction = 'bottom'; }
btn_left.onclick = function () { direction = 'left'; }
btn_right.onclick = function () { direction = 'right'; }



var snake = document.getElementsByClassName('snake');


snake[0].style.position = 'absolute';
snake[0].style.top = 250 + 'px';
snake[0].style.left = 250 + 'px';
snake[0].style.width = '50px';
snake[0].style.height = '50px';
snake[0].style['background-color'] = 'pink';
var boxpositionX = 250;
var boxpositionY = 250;
var start;
btn.onclick = function () {
    flag = !flag;
   
    btn.innerText = (flag == true ? '启动' : '暂停')
    if (flag) {
        start = setInterval(move, 200);
    } else {
        clearInterval(start);
    }
    console.log(1, flag)

}

function move() {
    if (flag) {
        [boxpositionX, boxpositionY] = changeDirection(boxpositionX, boxpositionY, direction)

        snake[0].style.left = boxpositionX + 'px';
        snake[0].style.top = boxpositionY + 'px';
        if (boxpositionX <= 0 || boxpositionX > body.clientX - 10 ||
            boxpositionY <= 0 || boxpositionY > body.clientY - 10) {
            flag = false;
        }

    }
}


function changeDirection(positionX, positionY, direction) {
    switch (direction) {
        case 'left': positionX = positionX - 10; break;
        case 'right': positionX = positionX + 10;; break;
        case 'top': positionY = positionY - 10;; break;
        case 'bottom': positionY = positionY + 10;; break;
    }
    if (direction == 'left') {
        positionX = positionX - 10;
    }
    return [positionX, positionY];
}