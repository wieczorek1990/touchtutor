import SwiftUI

struct MusicalNoteSymbolView: View {
  let noteType: NoteValueType
  let isDotted: Bool
  var size: CGFloat = 30
  var color: Color = .white

  var body: some View {
    Canvas { context, canvasSize in
      let w = canvasSize.width
      let h = canvasSize.height
      let scale = min(w / 32.0, h / 32.0)

      let isWholeOrBreve = (noteType == .whole || noteType == .breve)
      let headWidth: CGFloat = isWholeOrBreve ? (16.0 * scale) : (12.5 * scale)
      let headHeight: CGFloat = isWholeOrBreve ? (10.0 * scale) : (9.0 * scale)
      let headCenterX: CGFloat = isWholeOrBreve ? (w * 0.5) : (w * 0.38)
      let headCenterY: CGFloat = isWholeOrBreve ? (h * 0.5) : (h * 0.74)

      var headPath = Path()
      headPath.addEllipse(
        in: CGRect(x: -headWidth / 2, y: -headHeight / 2, width: headWidth, height: headHeight))
      let rotation = CGAffineTransform(rotationAngle: -22 * .pi / 180)
      let translation = CGAffineTransform(translationX: headCenterX, y: headCenterY)
      let transformedHead = headPath.applying(rotation.concatenating(translation))

      if noteType.isHollow {
        if isWholeOrBreve {
          context.stroke(transformedHead, with: .color(color), lineWidth: 2.8 * scale)
          if noteType == .breve {
            let barHeight = headHeight * 1.5
            let barWidth = 1.8 * scale
            let leftBar = CGRect(
              x: headCenterX - headWidth * 0.75, y: headCenterY - barHeight / 2, width: barWidth,
              height: barHeight)
            let rightBar = CGRect(
              x: headCenterX + headWidth * 0.75 - barWidth, y: headCenterY - barHeight / 2,
              width: barWidth, height: barHeight)
            context.fill(Path(leftBar), with: .color(color))
            context.fill(Path(rightBar), with: .color(color))
          }
        } else {
          context.stroke(transformedHead, with: .color(color), lineWidth: 2.4 * scale)
        }
      } else {
        context.fill(transformedHead, with: .color(color))
      }

      if noteType.hasStem {
        let stemX = headCenterX + (headWidth * 0.40)
        let stemStartY = headCenterY - (headHeight * 0.15)
        let stemTopY = h * 0.12
        let stemWidth = 2.2 * scale

        var stemPath = Path()
        stemPath.move(to: CGPoint(x: stemX, y: stemStartY))
        stemPath.addLine(to: CGPoint(x: stemX, y: stemTopY))
        context.stroke(
          stemPath, with: .color(color), style: StrokeStyle(lineWidth: stemWidth, lineCap: .round))

        let flags = noteType.flagsCount
        if flags > 0 {
          let flagSpacing: CGFloat = 4.2 * scale
          for i in 0..<flags {
            let flagStartY = stemTopY + CGFloat(i) * flagSpacing
            var flagPath = Path()
            flagPath.move(to: CGPoint(x: stemX, y: flagStartY))
            flagPath.addCurve(
              to: CGPoint(x: stemX + 8.5 * scale, y: flagStartY + 9.5 * scale),
              control1: CGPoint(x: stemX + 7.5 * scale, y: flagStartY + 2.0 * scale),
              control2: CGPoint(x: stemX + 8.5 * scale, y: flagStartY + 6.0 * scale)
            )
            flagPath.addCurve(
              to: CGPoint(x: stemX + 1.0 * scale, y: flagStartY + 6.5 * scale),
              control1: CGPoint(x: stemX + 6.0 * scale, y: flagStartY + 7.5 * scale),
              control2: CGPoint(x: stemX + 3.0 * scale, y: flagStartY + 6.0 * scale)
            )
            flagPath.closeSubpath()
            context.fill(flagPath, with: .color(color))
          }
        }
      }

      if isDotted {
        let dotRadius: CGFloat = 1.8 * scale
        let dotX = headCenterX + headWidth * 0.65 + 4.0 * scale
        let dotY = headCenterY
        let dotRect = CGRect(
          x: dotX - dotRadius, y: dotY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
        context.fill(Path(ellipseIn: dotRect), with: .color(color))
      }
    }
    .frame(width: size, height: size)
  }
}

struct TriangleCorner: Shape {
  var size: CGFloat = 54

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.maxX - size, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + size))
    path.closeSubpath()
    return path
  }
}
