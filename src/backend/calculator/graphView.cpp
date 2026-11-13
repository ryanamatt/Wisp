// src/backend/calculator/graphView.cpp

#include "graphView.hpp"
#include "calcParser.hpp"
#include <QMouseEvent>
#include <QSGFlatColorMaterial>
#include <QSGGeometryNode>
#include <QWheelEvent>
#include <algorithm>
#include <cmath>
#include <memory>
#include <qqmllist.h>
#include <qsggeometry.h>
#include <qtypes.h>

namespace {

constexpr double kMinScale = 1e-6;
constexpr double kMaxScale = 1e8;

// Pixel y is clamped to this so huge values cannot blow up the vertices.
constexpr double kPixelClamp = 1e5;

// Adjacent samples further apart than this (vertically, in pixels) are
// split in half, so steep parts of a curve stay smooth.
constexpr double kRefinePx = 3.0;
constexpr int kMaxDepth = 10;

// Segments off-screen by more than this on the same side are not drawn.
constexpr double kCullMargin = 50.0;

} // namespace

GraphView::GraphView(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
    setAcceptedMouseButtons(Qt::LeftButton);
    setClip(true);
}

// --- Functions list ---

QQmlListProperty<GraphFunction> GraphView::functions() {
    return QQmlListProperty<GraphFunction>(this, this, &GraphView::functionAppend, &GraphView::functionCount,
            &GraphView::functionAt, &GraphView::functionClear);
}

qsizetype GraphView::functionCount(QQmlListProperty<GraphFunction> *list) {
    return static_cast<GraphView *>(list->object)->m_functions.size();
}

GraphFunction *GraphView::functionAt(QQmlListProperty<GraphFunction> *list, qsizetype index) {
    return static_cast<GraphView *>(list->object)->m_functions.value(index);
}

void GraphView::functionAppend(QQmlListProperty<GraphFunction> *list, GraphFunction *fn) {
    static_cast<GraphView *>(list->object)->addFunction(fn);
}

void GraphView::functionClear(QQmlListProperty<GraphFunction> *list) {
    auto *view = static_cast<GraphView *>(list->object);
    for (const auto &fn : std::as_const(view->m_functions)) {
        if (fn) fn->disconnect(view);
    }
    view->m_functions.clear();
    view->update();
    emit view->functionsChanged();
}

void GraphView::addFunction(GraphFunction *fn) {
    if (!fn || m_functions.contains(fn)) return;

    m_functions.append(fn);
    connect(fn, &GraphFunction::changed, this, [this]() { update(); });
    connect(fn, &QObject::destroyed, this, [this]() {
        // The QPointer is already null here, so drop the dead entry.
        m_functions.removeIf([](const QPointer<GraphFunction> &p) { return p.isNull(); });
        update();
        emit functionsChanged();
    });
    update();
    emit functionsChanged();
}

void GraphView::removeFunction(GraphFunction *fn) {
    if (!fn) return;

    fn->disconnect(this);
    m_functions.removeAll(fn);
    update();
    emit functionsChanged();
}

// --- viewport ---

void GraphView::notifyViewport() {
    emit viewportChanged();
    update();
}

void GraphView::setCenterX(double v) {
    if (v == m_centerX || !std::isfinite(v)) return;
    m_centerX = v;
    notifyViewport();
}

void GraphView::setCenterY(double v) {
    if (v == m_centerY || !std::isfinite(v)) return;
    m_centerY = v;
    notifyViewport();
}

void GraphView::setScale(double v) {
    if (!std::isfinite(v)) return;
    v = std::clamp(v, kMinScale, kMaxScale);
    if (v == m_scale) return;
    m_scale = v;
    notifyViewport();
}

double GraphView::toGraphX(double px) const { return m_centerX + (px - width() / 2.0) / m_scale; }
double GraphView::toGraphY(double py) const { return m_centerY - (py - height() / 2.0) / m_scale; }
double GraphView::toPixelX(double gx) const { return width() / 2.0 + (gx - m_centerX) * m_scale; }
double GraphView::toPixelY(double gy) const { return height() / 2.0 - (gy - m_centerY) * m_scale; }

double GraphView::xMin() const { return toGraphX(0.0); }
double GraphView::xMax() const { return toGraphX(width()); }
double GraphView::yMin() const { return toGraphY(height()); }
double GraphView::yMax() const { return toGraphY(0.0); }

double GraphView::gridStep() const {
    double raw = 90.0 / m_scale;
    double magnitude = std::pow(10.0, std::floor(std::log10(raw)));
    double m = raw / magnitude;
    double mult = m < 1.5 ? 1.0 : m < 3.5 ? 2.0 : m < 7.5 ? 5.0 : 10.0;
    return mult * magnitude;
}

void GraphView::setLineWidth(double w) {
    if (w == m_lineWidth || !(w > 0.0)) return;
    m_lineWidth = w;
    emit lineWidthChanged();
    update();
}

void GraphView::setInteractive(bool on) {
    if (on == m_interactive) return;
    m_interactive = on;
    m_dragging = false;
    setAcceptedMouseButtons(on ? Qt::LeftButton : Qt::NoButton);
    emit interactiveChanged();
}

void GraphView::panBy(double dxPixels, double dyPixels) {
    m_centerX -= dxPixels / m_scale;
    m_centerY += dyPixels / m_scale;
    notifyViewport();
}

void GraphView::zoomAt(double px, double py, double factor) {
    if (!(factor > 0.0) || !std::isfinite(factor)) return;

    double newScale = std::clamp(m_scale * factor, kMinScale, kMaxScale);
    if (newScale == m_scale) return;

    // Keep the graph point under the cursor where it is.
    double gx = toGraphX(px);
    double gy = toGraphY(py);
    m_scale = newScale;
    m_centerX = gx - (px - width() / 2.0) / m_scale;
    m_centerY = gy + (py - height() / 2.0) / m_scale;
    notifyViewport();
}

void GraphView::resetView() {
    m_centerX = 0.0;
    m_centerY = 0.0;
    m_scale = 50.0;
    notifyViewport();
}

void GraphView::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (newGeometry.size() != oldGeometry.size()) notifyViewport();
}

// --- input ---

void GraphView::mousePressEvent(QMouseEvent *event) {
    if (!m_interactive) {
        event->ignore();
        return;
    }
    m_dragging = true;
    m_lastMouse = event->position();
    event->accept();
}

void GraphView::mouseMoveEvent(QMouseEvent *event) {
    if (!m_dragging) return;
    QPointF pos = event->position();
    panBy(pos.x() - m_lastMouse.x(), pos.y() - m_lastMouse.y());
    m_lastMouse = pos;
}

void GraphView::mouseReleaseEvent(QMouseEvent *) { m_dragging = false; }

void GraphView::mouseUngrabEvent() { m_dragging = false; }

void GraphView::wheelEvent(QWheelEvent *event) {
    if (!m_interactive) {
        event->ignore();
        return;
    }
    double factor = std::pow(1.0015, (double)event->angleDelta().y());
    zoomAt(event->position().x(), event->position().y(), factor);
    event->accept();
}

// --- curve building ---

GraphView::PixelPoint GraphView::samplePoint(const wisp::calc::Expression &expr, double px) const {
    double gy = expr.eval(toGraphX(px), 0.0);
    if (!std::isfinite(gy)) return {px, 0.0, false};

    double py = std::clamp(toPixelY(gy), -kPixelClamp, kPixelClamp);
    return {px, py, true};
}

void GraphView::addQuad(const PixelPoint &a, const PixelPoint &b, std::vector<QSGGeometry::Point2D> &out) const {
    double dx = b.x - a.x;
    double dy = b.y - a.y;
    double len = std::hypot(dx, dy);
    if (len < 1e-9) return;

    double ux = dx / len;
    double uy = dy / len;
    double hw = m_lineWidth / 2.0;

    // Overlap neighbouring quads by half a pixel so joints have no cracks
    double ax = a.x - ux * 0.5, ay = a.y - uy * 0.5;
    double bx = b.x + ux * 0.5, by = b.y + uy * 0.5;

    float nx = (float)(-uy * hw);
    float ny = (float)(ux * hw);

    QSGGeometry::Point2D p0, p1, p2, p3;
    p0.set((float)ax + nx, (float)ay + ny);
    p1.set((float)ax - nx, (float)ay - ny);
    p2.set((float)bx + nx, (float)by + ny);
    p3.set((float)bx - nx, (float)by - ny);

    out.push_back(p0);
    out.push_back(p1);
    out.push_back(p2);
    out.push_back(p2);
    out.push_back(p1);
    out.push_back(p3);
}

void GraphView::addSegment(const wisp::calc::Expression &expr, const PixelPoint &a, const PixelPoint &b, int depth, std::vector<QSGGeometry::Point2D> &out) const {
    // Undefined at either end, leave a gap.
    if (!a.ok || !b.ok) return;

    double h = height();
    if (a.y < -kCullMargin && b.y < -kCullMargin) return;
    if (a.y > h + kCullMargin && b.y > h + kCullMargin) return;

    double dy = std::fabs(b.y - a.y);

    if (dy > kRefinePx && depth < kMaxDepth) {
        PixelPoint mid = samplePoint(expr, (a.x + b.x) / 2.0);
        addSegment(expr, a, mid, depth + 1, out);
        addSegment(expr, mid, b, depth + 1, out);
        return;
    }

    // Still a huge jump after refining, a vertical asymptote such as tan(x).
    if (dy > std::max(8.0 * h, 2000.0)) return;

    addQuad(a, b, out);
}

void GraphView::buildCurve(const wisp::calc::Expression &expr, std::vector<QSGGeometry::Point2D> &out) const {
    int w = (int)std::ceil(width());
    if (w < 1) return;

    PixelPoint prev = samplePoint(expr, 0.0);
    for (int px = 1; px <= w; px++) {
        PixelPoint next = samplePoint(expr, (double)px);
        addSegment(expr, prev, next, 0, out);
        prev = next;
    }
}

// --- scene graph ---

QSGNode *GraphView::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    QSGNode *root = oldNode ? oldNode : new QSGNode;

    struct Drawable {
        std::shared_ptr<const wisp::calc::Equation> equation;
        QColor color;
    };

    std::vector<Drawable> drawables;
    for (const auto &fn : std::as_const(m_functions)) {
        if (!fn) continue;
        auto eq = fn->equation();
        if (eq) drawables.push_back({eq, fn->color()});
    }

    // One geometry node per drawable curve, reused between frames.
    const int needed = (int)drawables.size();
    while (root->childCount() > needed) delete root->lastChild();
    while (root->childCount() < needed) {
        auto *node = new QSGGeometryNode;

        auto *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        node->setMaterial(new QSGFlatColorMaterial);
        node->setFlag(QSGNode::OwnsMaterial);

        root->appendChildNode(node);
    }

    std::vector<QSGGeometry::Point2D> vertices;
    int i = 0;
    for (QSGNode *child = root->firstChild(); child; child = child->nextSibling(), ++i) {
        auto *node = static_cast<QSGGeometryNode *>(child);

        vertices.clear();
        buildCurve(drawables[(size_t)i].equation->lhs, vertices);

        QSGGeometry *geometry = node->geometry();
        geometry->allocate((int)vertices.size());
        if (!vertices.empty()) {
            std::copy(vertices.begin(), vertices.end(), geometry->vertexDataAsPoint2D());
        }

        static_cast<QSGFlatColorMaterial *>(node->material())->setColor(drawables[(size_t)i].color);
        node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    return root;
}

