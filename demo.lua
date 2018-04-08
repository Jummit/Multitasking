local ui = require "ui"

local elements = {}
elements = {
  button = ui.new.button({
    x = 10, y = 10, w = 10, h = 5,
    color = colors.blue, clickedColor = colors.lightBlue, textColor = colors.white,
    label = "test", clickedFunction = function()
      --error("", 0)
    end
  }),
  checkbox = ui.new.checkbox({
    x = 3, y = 3, color = colors.blue, textColor = colors.white
  }),
  textinput = ui.new.textinput({
    x = 10, y = 4, w = 10, h = 1, color = colors.blue, textColor = colors.white, selectedColor = colors.lightBlue,
    finishedFunction = function(text)
      if elements.checkbox.ticked then
        elements.textinput = nil
      end
    end
  }),
  window = ui.new.draggable({
    x = 25, y = 4, w = 6, h = 4, color = colors.blue
  })
}

ui.run(elements)
