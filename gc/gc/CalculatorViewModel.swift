//
//  CalculatorViewModel.swift
//  gc
//
//  Created by shashi kiran on 27/02/2026.
//

import Foundation
import Observation

@Observable
class CalculatorViewModel {
    var displayText = "0"

    private var currentNumber: Double = 0
    private var previousNumber: Double = 0
    private var currentOperation: Operation? = nil
    private var shouldResetDisplay = false
    private var hasDecimal = false
    private var lastButtonWasOperation = false

    enum Operation {
        case add, subtract, multiply, divide
    }

    func numberPressed(_ number: String) {
        lastButtonWasOperation = false

        if shouldResetDisplay {
            displayText = number
            shouldResetDisplay = false
            hasDecimal = false
        } else if displayText == "0" && number != "." {
            displayText = number
        } else {
            displayText += number
        }

        currentNumber = Double(displayText) ?? 0
    }

    func decimalPressed() {
        lastButtonWasOperation = false

        if shouldResetDisplay {
            displayText = "0."
            shouldResetDisplay = false
            hasDecimal = true
            return
        }

        if !hasDecimal {
            displayText += "."
            hasDecimal = true
        }
    }

    func operationPressed(_ operation: Operation) {
        if !lastButtonWasOperation && currentOperation != nil {
            calculateResult()
        }

        previousNumber = currentNumber
        currentOperation = operation
        shouldResetDisplay = true
        lastButtonWasOperation = true
    }

    func equalsPressed() {
        calculateResult()
        currentOperation = nil
        lastButtonWasOperation = false
    }

    func clearPressed() {
        displayText = "0"
        currentNumber = 0
        previousNumber = 0
        currentOperation = nil
        shouldResetDisplay = false
        hasDecimal = false
        lastButtonWasOperation = false
    }

    func toggleSign() {
        if currentNumber != 0 {
            currentNumber = -currentNumber
            displayText = formatNumber(currentNumber)
        }
    }

    func percentPressed() {
        currentNumber = currentNumber / 100
        displayText = formatNumber(currentNumber)
    }

    private func calculateResult() {
        guard let operation = currentOperation else { return }

        var result: Double

        switch operation {
        case .add:
            result = previousNumber + currentNumber
        case .subtract:
            result = previousNumber - currentNumber
        case .multiply:
            result = previousNumber * currentNumber
        case .divide:
            if currentNumber == 0 {
                displayText = "Error"
                currentNumber = 0
                previousNumber = 0
                currentOperation = nil
                shouldResetDisplay = true
                return
            }
            result = previousNumber / currentNumber
        }

        displayText = formatNumber(result)
        currentNumber = result
        previousNumber = result
        shouldResetDisplay = true
        hasDecimal = false
    }

    private func formatNumber(_ number: Double) -> String {
        if number == Double(Int(number)) && !number.isInfinite && !number.isNaN {
            return String(Int(number))
        }
        return String(number)
    }

    func isOperationActive(_ operation: Operation) -> Bool {
        guard lastButtonWasOperation else { return false }
        return currentOperation == operation
    }
}
