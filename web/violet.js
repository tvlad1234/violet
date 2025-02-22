const led_size = 30;
const led_dist = 35;
const led_x_offset = 35;
const led_y_offset = 60;

const btn_width = 30;
const btn_height = 50;
const btn_dist = 35;

const btn_x_offset = 35;
const btn_y_offset = 130;

const display_x_offset = 35;
const display_y_offset = 190;

const baudrate = 9600;

let port;
let connectBtn, buttons = [], displayP = [];

let board_ok = false;
let button_states = [], led_state = 0, display_data = 0;

function setup() {
  createCanvas(640, 320);
  background(220);

  port = createSerial();

  for (let i = 0; i < 16; i++) {
    buttons[i] = createButton(i);
    buttons[i].size(btn_width, btn_height);
    buttons[i].position(btn_x_offset + btn_dist * (15 - i), btn_y_offset + 20);
    buttons[i].mousePressed(() => button_states[i] = true);
    buttons[i].mouseReleased(() => button_states[i] = false);
  }

  connectBtn = createButton('Connect');
  connectBtn.position(10, 19);
  connectBtn.mousePressed(connectBtnClick);

  for (let i = 0; i < 4; i++) {

    displayP[i] = createP("0");
    displayP[i].position(display_x_offset + 35 * i, display_y_offset);
    displayP[i].class("sevseg");
  }
  setInterval(board_comms, 25);
}

function draw() {

  background(220);

  if (!port.opened()) {
    connectBtn.html('Connect');
  } else {
    connectBtn.html('Disconnect');
    if (!board_ok) {
      stroke(255, 0, 0);
      fill(255, 0, 0);
      text("No board response!", 200, 33);
    }
  }

  stroke(0, 0, 0);
  fill(0, 0, 0);

  text("Display", display_x_offset + 15, display_y_offset + 35);
  rect(display_x_offset - 5, display_y_offset + 42, 153, 54)

  let d = display_data;
  for (let i = 0; i < 4; i++) {
    let digit = d & 0xF;
    d >>= 4;
    displayP[3 - i].html(digit.toString(16));
  }

  text("LED", led_x_offset + led_size / 2, led_y_offset);
  text("Buttons", btn_x_offset + btn_width / 2, btn_y_offset + 5);

  let led_data = led_state;
  for (let i = 0; i < 16; i++) {

    stroke(0, 0, 0);
    fill(0, 0, 0);
    textAlign(CENTER);
    text(i, led_x_offset + (led_size / 2) + led_dist * (15 - i), led_y_offset + 20 + led_size);
    stroke(89, 62, 107)
    if (led_data & 1)
      fill(218, 179, 245);
    else fill(89, 62, 107)
    circle(led_x_offset + (led_size / 2) + led_dist * (15 - i), led_y_offset + 20, led_size);
    led_data = led_data >> 1;
  }

}

function connectBtnClick() {
  if (!port.opened()) {
    port.open(baudrate);
  } else {
    port.close();
  }
}

let buttons_prev;
let read_reg = "led";

function board_comms() {
  if (port.opened()) {

    if (port.availableBytes() == 2) {
      let a = port.readBytes();

      let received = a[0] + (a[1] << 8);

      if (read_reg == "led")
        led_state = received;

      else if (read_reg == "display")
        display_data = received;

      board_ok = true;
    }
    else board_ok = false;

    port.clear();


    if (read_reg == "led")
      read_reg = "display";
    else read_reg = "led";

    if (read_reg == "led") {
      let ledcmd = [1, 0, 0];
      port.write(ledcmd);
    }
    else if (read_reg == "display") {
      let dispcmd = [3, 0, 0];
      port.write(dispcmd);
    }

    let buttons_current = 0;
    for (let i = 0; i < 16; i++) {
      if (button_states[15 - i])
        buttons_current++;
      buttons_current = buttons_current << 1;
    }
    buttons_current = buttons_current >> 1;

    if (buttons_current != buttons_prev) {
      let buttoncmd = [2, buttons_current & 255, (buttons_current >> 8) & 255];
      port.write(buttoncmd);
    }
    buttons_prev = buttons_current;

  }
}

