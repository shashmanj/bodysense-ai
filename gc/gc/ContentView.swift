//
//  ContentView.swift
//  gc
//
//  Created by shashi kiran  on 27/02/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = CalculatorViewModel()

    private let buttons: [[CalcButton]] = [
        [.clear, .toggleSign, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()

                // Display
                HStack {
                    Spacer()
                    Text(viewModel.displayText)
                        .font(.system(size: displayFontSize, weight: .light))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 24)
                }

                // Buttons
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButtonView(
                                button: button,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var displayFontSize: CGFloat {
        if viewModel.displayText.count > 9 {
            return 50
        } else if viewModel.displayText.count > 6 {
            return 64
        }
        return 80
    }
}

struct CalculatorButtonView: View {
    let button: CalcButton
    let viewModel: CalculatorViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            Button(action: { buttonAction() }) {
                Text(button.title)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(button.foregroundColor(isHighlighted: isHighlighted))
                    .frame(
                        width: totalWidth,
                        height: button == .zero ? totalWidth / 2.15 : totalWidth
                    )
                    .background(button.backgroundColor(isHighlighted: isHighlighted))
                    .clipShape(button == .zero
                        ? AnyShape(Capsule())
                        : AnyShape(Circle())
                    )
            }
        }
        .aspectRatio(button == .zero ? 2.15 : 1, contentMode: .fit)
    }

    private var isHighlighted: Bool {
        switch button {
        case .add: return viewModel.isOperationActive(.add)
        case .subtract: return viewModel.isOperationActive(.subtract)
        case .multiply: return viewModel.isOperationActive(.multiply)
        case .divide: return viewModel.isOperationActive(.divide)
        default: return false
        }
    }

    private func buttonAction() {
        switch button {
        case .zero, .one, .two, .three, .four,
             .five, .six, .seven, .eight, .nine:
            viewModel.numberPressed(button.title)
        case .decimal:
            viewModel.decimalPressed()
        case .add:
            viewModel.operationPressed(.add)
        case .subtract:
            viewModel.operationPressed(.subtract)
        case .multiply:
            viewModel.operationPressed(.multiply)
        case .divide:
            viewModel.operationPressed(.divide)
        case .equals:
            viewModel.equalsPressed()
        case .clear:
            viewModel.clearPressed()
        case .toggleSign:
            viewModel.toggleSign()
        case .percent:
            viewModel.percentPressed()
        }
    }
}

enum CalcButton: String, Hashable {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case add = "+", subtract = "-", multiply = "×", divide = "÷"
    case equals = "=", decimal = ".", clear = "AC"
    case toggleSign = "+/-", percent = "%"

    var title: String { rawValue }

    func backgroundColor(isHighlighted: Bool) -> Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return isHighlighted ? .white : .orange
        case .clear, .toggleSign, .percent:
            return Color(.lightGray)
        default:
            return Color(.darkGray)
        }
    }

    func foregroundColor(isHighlighted: Bool) -> Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return isHighlighted ? .orange : .white
        case .clear, .toggleSign, .percent:
            return .black
        default:
            return .white
        }
    }
}

#Preview {
    ContentView()
}
