import SwiftUI

struct TopicVisualView: View {
    let visual: TopicVisual
    var compact: Bool = false
    var revealAnswer: Bool = false

    var body: some View {
        Group {
            switch visual {
            case .fraction(let numerator, let denominator):
                FractionBarView(numerator: numerator, denominator: denominator, compact: compact)
            case .decimalGrid(let tenths):
                DecimalGridView(tenths: tenths, compact: compact)
            case .percentGrid(let percent):
                PercentGridView(percent: percent, compact: compact)
            case .clock(let hour, let minute):
                ClockView(hour: hour, minute: minute, compact: compact)
            case .money(let pieces):
                MoneyView(pieces: pieces, compact: compact, revealAnswer: revealAnswer)
            case .ruler(let lengthA, let lengthB, let unit):
                RulerCompareView(lengthA: lengthA, lengthB: lengthB, unit: unit, compact: compact)
            case .shape(let kind, let width, let height):
                GeometryShapeView(kind: kind, width: width, height: height, compact: compact)
            case .barGraph(let items):
                BarGraphView(items: items, compact: compact)
            case .placeValue(let number):
                PlaceValueView(number: number, compact: compact)
            case .spinner(let redSections, let totalSections):
                SpinnerView(redSections: redSections, totalSections: totalSections, compact: compact)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(compact ? 8 : 12)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct FractionBarView: View {
    let numerator: Int
    let denominator: Int
    var compact: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<denominator, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(index < numerator ? AppTheme.coral : AppTheme.coral.opacity(0.15))
                    .frame(height: compact ? 36 : 48)
            }
        }
        .accessibilityLabel("\(numerator) of \(denominator) parts shaded")
    }
}

private struct DecimalGridView: View {
    let tenths: Int
    var compact: Bool

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index < tenths ? AppTheme.teal : AppTheme.teal.opacity(0.12))
                    .frame(height: compact ? 20 : 28)
            }
        }
    }
}

private struct PercentGridView: View {
    let percent: Int
    var compact: Bool

    var body: some View {
        let filled = max(0, min(100, percent))
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 10), spacing: 3) {
            ForEach(0..<100, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index < filled ? AppTheme.purple : AppTheme.purple.opacity(0.12))
                    .frame(height: compact ? 10 : 14)
            }
        }
        .accessibilityLabel("\(filled) out of 100 squares shaded")
    }
}

private struct ClockView: View {
    let hour: Int
    let minute: Int
    var compact: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.ink.opacity(0.15), lineWidth: 3)
                .frame(width: compact ? 120 : 160, height: compact ? 120 : 160)
            Rectangle()
                .fill(AppTheme.ink)
                .frame(width: 3, height: compact ? 34 : 46)
                .offset(y: compact ? -17 : -23)
                .rotationEffect(.degrees(Double(hour % 12) * 30 + Double(minute) * 0.5))
            Rectangle()
                .fill(AppTheme.teal)
                .frame(width: 2, height: compact ? 48 : 64)
                .offset(y: compact ? -24 : -32)
                .rotationEffect(.degrees(Double(minute) * 6))
            Circle().fill(AppTheme.ink).frame(width: 8, height: 8)
        }
    }
}

private struct MoneyView: View {
    let pieces: [MoneyPiece]
    var compact: Bool
    var revealAnswer: Bool

    private var bills: [MoneyPiece] { pieces.filter { $0.kind == .bill } }
    private var coins: [MoneyPiece] { pieces.filter { $0.kind == .coin } }
    private var totalCents: Int { pieces.reduce(0) { $0 + $1.valueCents } }
    private var addExpression: String {
        pieces.map(\.centsLabel).joined(separator: " + ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 16) {
            if !bills.isEmpty {
                section(title: "Bills", reminder: "Each dollar is 100 cents") {
                    FlexibleMoneyRow(spacing: compact ? 10 : 12) {
                        ForEach(Array(bills.enumerated()), id: \.offset) { _, bill in
                            labeledPiece(bill)
                        }
                    }
                }
            }

            if !coins.isEmpty {
                section(title: "Coins", reminder: "Quarter 25¢ · Dime 10¢ · Nickel 5¢") {
                    FlexibleMoneyRow(spacing: compact ? 10 : 12) {
                        ForEach(Array(coins.enumerated()), id: \.offset) { _, coin in
                            labeledPiece(coin)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HelperStepLabel(text: "Add the cents", color: AppTheme.sunny)
                Text(addExpression)
                    .font(.system(size: compact ? 16 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if revealAnswer {
                    Text("= \(totalCents) cents")
                        .font(.system(size: compact ? 20 : 24, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.teal)
                } else {
                    Text("= ? cents")
                        .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink.opacity(0.45))
                }
            }
            .padding(compact ? 10 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.sunny.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let names = pieces.map(\.helperLine).joined(separator: ". ")
        if revealAnswer {
            return "\(names). Total \(totalCents) cents."
        }
        return "\(names). Add the cents."
    }

    private func section(title: String, reminder: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink.opacity(0.7))
            Text(reminder)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.55))
            content()
        }
    }

    private func labeledPiece(_ piece: MoneyPiece) -> some View {
        VStack(spacing: 6) {
            if piece.kind == .bill {
                billCard(piece)
            } else {
                coinCircle(piece)
            }
            Text(piece.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
            Text(piece.centsLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.teal)
        }
        .frame(minWidth: compact ? 72 : 86)
    }

    private func billCard(_ piece: MoneyPiece) -> some View {
        let dollars = piece.valueCents / 100
        return RoundedRectangle(cornerRadius: compact ? 8 : 10)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.78, blue: 0.55), Color(red: 0.32, green: 0.58, blue: 0.38)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: compact ? 96 : 118, height: compact ? 52 : 64)
            .overlay {
                VStack(spacing: 2) {
                    Text("$\(dollars)")
                        .font(.system(size: compact ? 20 : 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(piece.valueCents) cents")
                        .font(.system(size: compact ? 9 : 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 8 : 10)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }

    private func coinCircle(_ piece: MoneyPiece) -> some View {
        let style = coinStyle(for: piece.valueCents)
        return Circle()
            .fill(style.color)
            .frame(width: compact ? 44 : 56, height: compact ? 44 : 56)
            .overlay {
                Text(style.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5)
            }
    }

    private func coinStyle(for cents: Int) -> (label: String, color: Color) {
        switch cents {
        case 25: ("25¢", AppTheme.sunny)
        case 10: ("10¢", AppTheme.teal)
        case 5: ("5¢", AppTheme.coral)
        default: ("1¢", AppTheme.purple.opacity(0.8))
        }
    }
}

private struct FlexibleMoneyRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, point) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        var positions: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            width = max(width, x - spacing)
        }

        return (CGSize(width: width, height: y + rowHeight), positions)
    }
}

private struct RulerCompareView: View {
    let lengthA: Int
    let lengthB: Int
    let unit: String
    var compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            bar(label: "A", length: lengthA, color: AppTheme.teal)
            bar(label: "B", length: lengthB, color: AppTheme.coral)
        }
    }

    private func bar(label: String, length: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.headline.weight(.bold))
                .frame(width: 20)
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.85))
                .frame(width: CGFloat(length) * (compact ? 14 : 18), height: compact ? 18 : 22)
            Text("\(length) \(unit)")
                .font(.caption.weight(.semibold))
        }
    }
}

private struct GeometryShapeView: View {
    let kind: GeometryShape
    let width: Int
    let height: Int
    var compact: Bool

    var body: some View {
        switch kind {
        case .rectangle, .square:
            GridShapeView(columns: width, rows: height, compact: compact)
        case .triangle:
            TriangleShape()
                .fill(AppTheme.purple.opacity(0.75))
                .frame(width: compact ? 90 : 120, height: compact ? 80 : 100)
        case .circle:
            Circle()
                .fill(AppTheme.teal.opacity(0.75))
                .frame(width: compact ? 90 : 110, height: compact ? 90 : 110)
        case .hexagon:
            RegularPolygon(sides: 6)
                .fill(AppTheme.sunny.opacity(0.85))
                .frame(width: compact ? 90 : 110, height: compact ? 90 : 110)
        }
    }
}

private struct GridShapeView: View {
    let columns: Int
    let rows: Int
    var compact: Bool

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 3) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.purple.opacity(0.7))
                            .frame(width: compact ? 18 : 24, height: compact ? 18 : 24)
                            .overlay {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(.white.opacity(0.6), lineWidth: 1)
                            }
                    }
                }
            }
        }
    }
}

private struct BarGraphView: View {
    let items: [BarGraphItem]
    var compact: Bool

    var body: some View {
        let maxValue = max(items.map(\.value).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(graphColor(index))
                        .frame(
                            width: compact ? 28 : 36,
                            height: CGFloat(item.value) / CGFloat(maxValue) * (compact ? 80 : 110)
                        )
                    Text(item.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.ink.opacity(0.7))
                }
            }
        }
    }

    private func graphColor(_ index: Int) -> Color {
        [AppTheme.coral, AppTheme.teal, AppTheme.sunny, AppTheme.purple][index % 4]
    }
}

private struct PlaceValueView: View {
    let number: Int
    var compact: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
                VStack(spacing: 4) {
                    Text("\(digit)")
                        .font(.system(size: compact ? 28 : 36, weight: .bold, design: .rounded))
                    Text(placeName(index: index, total: digits.count))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(AppTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var digits: [Int] {
        String(number).compactMap { Int(String($0)) }
    }

    private func placeName(index: Int, total: Int) -> String {
        let names = ["Ones", "Tens", "Hundreds"]
        let reversedIndex = total - index - 1
        return reversedIndex < names.count ? names[reversedIndex] : "Place"
    }
}

private struct SpinnerView: View {
    let redSections: Int
    let totalSections: Int
    var compact: Bool

    var body: some View {
        ZStack {
            ForEach(0..<max(totalSections, 1), id: \.self) { index in
                SpinnerSlice(
                    startAngle: .degrees(Double(index) / Double(max(totalSections, 1)) * 360),
                    endAngle: .degrees(Double(index + 1) / Double(max(totalSections, 1)) * 360)
                )
                .fill(index < redSections ? AppTheme.coral : AppTheme.teal.opacity(0.35))
            }
        }
        .frame(width: compact ? 110 : 140, height: compact ? 110 : 140)
    }
}

private struct SpinnerSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: min(rect.width, rect.height) / 2, startAngle: startAngle - .degrees(90), endAngle: endAngle - .degrees(90), clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct RegularPolygon: Shape {
    let sides: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<sides {
            let angle = (Double(i) / Double(sides)) * 2 * Double.pi - Double.pi / 2
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
