package com.kiwidev.physical.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.unit.dp
import com.kiwidev.physical.ui.Palette.Accent
import com.kiwidev.physical.ui.Palette.Ink

/**
 * Icons traced from the design's SVG exports. Each 44 × 44 glyph keeps the artboard's
 * absolute coordinates; (x, y) is the top-left of its viewBox. Colors are baked in:
 * draw with `tint = Color.Unspecified`.
 */
object Glyphs {
    private const val PROFILE = "M363.667 650C363.667 650 362 650 362 648.333C362 646.667 363.667 641.667 372 641.667C380.333 641.667 382 646.667 382 648.333C382 650 380.333 650 380.333 650H363.667ZM372 640C373.326 640 374.598 639.473 375.536 638.536C376.473 637.598 377 636.326 377 635C377 633.674 376.473 632.402 375.536 631.464C374.598 630.527 373.326 630 372 630C370.674 630 369.402 630.527 368.464 631.464C367.527 632.402 367 633.674 367 635C367 636.326 367.527 637.598 368.464 638.536C369.402 639.473 370.674 640 372 640Z"
    val Profile = glyph("profile", 350f, 618f) { fill(PROFILE) }
    /** Not in the design export: Accent fill + Ink outline, like the other active tabs. */
    val ProfileOn = glyph("profile-on", 350f, 618f) { stroke(PROFILE, 1.5f, fill = Accent) }
    val Heart = glyph("heart", 350f, 662f) {
        fill("M381.516 678.689C381.206 677.967 380.758 677.313 380.199 676.763C379.639 676.212 378.979 675.773 378.254 675.472C377.503 675.159 376.697 674.998 375.884 675C374.742 675 373.629 675.314 372.661 675.907C372.429 676.049 372.21 676.205 372.001 676.375C371.793 676.205 371.573 676.049 371.341 675.907C370.374 675.314 369.26 675 368.119 675C367.297 675 366.501 675.158 365.748 675.472C365.021 675.775 364.366 676.209 363.803 676.763C363.243 677.312 362.796 677.966 362.486 678.689C362.164 679.44 362 680.238 362 681.059C362 681.833 362.157 682.64 362.47 683.461C362.732 684.147 363.107 684.859 363.586 685.578C364.345 686.715 365.389 687.901 366.686 689.104C368.834 691.097 370.962 692.474 371.052 692.53L371.601 692.883C371.844 693.039 372.156 693.039 372.399 692.883L372.948 692.53C373.038 692.471 375.164 691.097 377.314 689.104C378.611 687.901 379.655 686.715 380.414 685.578C380.893 684.859 381.271 684.147 381.53 683.461C381.843 682.64 382 681.833 382 681.059C382.002 680.238 381.838 679.44 381.516 678.689ZM372.001 691.043C372.001 691.043 363.759 685.738 363.759 681.059C363.759 678.689 365.711 676.768 368.119 676.768C369.811 676.768 371.279 677.717 372.001 679.103C372.723 677.717 374.191 676.768 375.884 676.768C378.291 676.768 380.243 678.689 380.243 681.059C380.243 685.738 372.001 691.043 372.001 691.043Z")
    }
    val HeartOn = glyph("heart-on", 350f, 662f) {
        stroke("M372.001 691.6C372.001 691.6 363 686 363 681.059C363 678.3 365.2 676 368.119 676C369.811 676 371.279 676.9 372.001 678.3C372.723 676.9 374.191 676 375.884 676C378.8 676 381 678.3 381 681.059C381 686 372.001 691.6 372.001 691.6Z", 1.6f, fill = Accent)
    }
    val Disc = glyph("disc", 350f, 706f) {
        stroke(circle(372f, 728f, 10f), 1.5f)
        stroke(circle(372f, 728f, 2f), 1.5f)
    }
    val DiscOn = glyph("disc-on", 350f, 706f) {
        stroke(circle(372f, 728f, 10f), 1.5f, fill = Accent)
        stroke(circle(372f, 728f, 2f), 1.5f)
    }
    val Search = glyph("search", 350f, 752f) {
        stroke(circle(371.091f, 772.091f, 8.34f), 1.5f)
        stroke("M375.788 779.364L382 785.576", 1.5f)
    }
    val SearchOn = glyph("search-on", 350f, 752f) {
        stroke(circle(371.091f, 772.091f, 8.34f), 1.5f, fill = Accent)
        stroke("M375.788 779.364L382 785.576", 1.5f)
    }
    private const val HOME = "M362 821.175V827.72C362 829.091 362 829.776 362.272 830.301C362.512 830.761 362.894 831.136 363.365 831.37C363.899 831.636 364.599 831.636 365.996 831.636H378.004C379.401 831.636 380.1 831.636 380.634 831.37C381.104 831.135 381.487 830.761 381.727 830.301C382 829.777 382 829.093 382 827.725V821.175C382 820.522 382 820.195 381.919 819.89C381.847 819.621 381.728 819.366 381.569 819.135C381.388 818.875 381.137 818.658 380.634 818.228L374.634 813.088C373.701 812.289 373.234 811.889 372.709 811.737C372.246 811.603 371.754 811.603 371.29 811.737C370.765 811.889 370.3 812.288 369.368 813.086L363.366 818.228C362.864 818.659 362.613 818.875 362.433 819.134C362.272 819.365 362.153 819.62 362.081 819.89C362 820.194 362 820.522 362 821.175Z"
    val Home = glyph("home", 350f, 800f) { stroke(HOME, 1.5f) }
    val HomeOn = glyph("home-on", 350f, 800f) { stroke(HOME, 2f, fill = Accent) }
    val Scan = glyph("scan", 23f, 850f) {
        fill("M30 857V856H29V857H30ZM60 857H61V856H60V857ZM30 857V858H60V857V856H30V857ZM60 857H59V862H60H61V857H60ZM30 862H31V857H30H29V862H30Z")
        stroke("M35 871.5H55", 1f, cap = StrokeCap.Butt)
        fill("M30 887V888H29V887H30ZM60 887H61V888H60V887ZM30 887V886H60V887V888H30V887ZM60 887H59V882H60H61V887H60ZM30 882H31V887H30H29V882H30Z")
    }
    val Plus = glyph("plus", 78f, 850f) {
        stroke("M87.5 872H112.5", 2f, Accent, cap = StrokeCap.Butt)
        stroke("M100.5 859.5V884.5", 2f, Accent, cap = StrokeCap.Butt)
    }
    /** 24 × 24, single color: tint it. */
    val Pencil = ImageVector.Builder("pencil", 24.dp, 24.dp, 24f, 24f).apply {
        addPath(
            addPathNodes("M4 20l1-4L16 5a2.1 2.1 0 0 1 3 3L8 19l-4 1zM14 7l3 3"),
            stroke = SolidColor(Color.Black), strokeLineWidth = 1.7f, strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round,
        )
    }.build()
    /** 24 × 24, single color: tint it. */
    val Star = ImageVector.Builder("star", 24.dp, 24.dp, 24f, 24f).apply {
        addPath(addPathNodes("M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6L2.5 9.4l6.6-.8z"), fill = SolidColor(Color.Black))
    }.build()
}

private fun glyph(name: String, x: Float, y: Float, block: ImageVector.Builder.() -> Unit) =
    ImageVector.Builder(name, 44.dp, 44.dp, 44f, 44f).apply {
        addGroup(translationX = -x, translationY = -y)
        block()
        clearGroup()
    }.build()

private fun ImageVector.Builder.fill(d: String, color: Color = Ink) {
    addPath(addPathNodes(d), fill = SolidColor(color))
}

private fun ImageVector.Builder.stroke(d: String, width: Float, color: Color = Ink, fill: Color? = null, cap: StrokeCap = StrokeCap.Round) {
    addPath(
        addPathNodes(d), fill = fill?.let(::SolidColor), stroke = SolidColor(color),
        strokeLineWidth = width, strokeLineCap = cap, strokeLineJoin = StrokeJoin.Round,
    )
}

private fun circle(cx: Float, cy: Float, r: Float) = "M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 ${-2 * r} 0Z"
