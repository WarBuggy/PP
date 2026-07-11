-- ModI: patch ModH.MathUtils

function MathUtils.divide(a, b)
    if b == 0 then
        error("Division by zero")
    end
    return a / b
end