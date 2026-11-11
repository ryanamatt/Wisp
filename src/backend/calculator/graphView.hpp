// src/backend/calculator/graphView.hpp
//
// Scene graph item that draws curves. Grid, axes and labels are left to QML
// so they follow the shell theme; this item exposes the viewport and a nice
// grid step for that.
//
// Viewport: (centerX, centerY) is the graph point at the middle of the item
// and `scale` is pixels per graph unit (the same on both axes).

#pragma once

#include "graphFunction.hpp"
#include <QColor>
#include <QList>
#include <QPointF>
#include <QPointer>
#include <QQmlListProperty>
#include <QQmlEngine>
#include <QQuickItem>
#include <QSGGeometry>
#include <QSGNode>
#include <vector>

class GraphView : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQmlListProperty<GraphFunction> functions READ functions NOTIFY functionsChanged)
    Q_PROPERTY(double centerX READ centerX WRITE setCenterX NOTIFY viewportChanged)
    Q_PROPERTY(double centerY READ centerY WRITE setCenterY NOTIFY viewportChanged)
    Q_PROPERTY(double scale READ scale WRITE setScale NOTIFY viewportChanged)
    Q_PROPERTY(double xMin READ xMin NOTIFY viewportChanged)
    Q_PROPERTY(double xMax READ xMax NOTIFY viewportChanged)
    Q_PROPERTY(double yMin READ yMin NOTIFY viewportChanged)
    Q_PROPERTY(double yMax READ yMax NOTIFY viewportChanged)
    // A 1/2/5 step (in graph units) that gives roughly 90px between grid lines.
    Q_PROPERTY(double gridStep READ gridStep NOTIFY viewportChanged)
    Q_PROPERTY(double lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)
    // Built-in drag to pan and wheel to zoom.
    Q_PROPERTY(bool interactive READ interactive WRITE setInteractive NOTIFY interactiveChanged)

public:
    explicit GraphView(QQuickItem *parent = nullptr);

    QQmlListProperty<GraphFunction> functions();

    double centerX() const {
        return m_centerX;
    }

    double centerY() const {
        return m_centerY;
    }

    double scale() const {
        return m_scale;
    }

    void setCenterX(double v);
    void setCenterY(double v);
    void setScale(double v);

    double xMin() const;
    double xMax() const;
    double yMin() const;
    double yMax() const;
    double gridStep() const;

    double lineWidth() const {
        return m_lineWidth;
    }
    void setLineWidth(double w);

    bool interactive() const {
        return m_interactive;
    }
    void setInteractive(bool on);

    Q_INVOKABLE void addFunction(GraphFunction *fn);
    Q_INVOKABLE void removeFunction(GraphFunction *fn);
    Q_INVOKABLE void panBy(double dxPixels, double dyPixels);
    // Zoom keeping the graph point under (px, py) fixed. factor > 1 zooms in.
    Q_INVOKABLE void zoomAt(double px, double py, double factor);
    Q_INVOKABLE void resetView();

    // Pixel (item) coordinates <-> graph coordinates.
    Q_INVOKABLE double toGraphX(double px) const;
    Q_INVOKABLE double toGraphY(double py) const;
    Q_INVOKABLE double toPixelX(double gx) const;
    Q_INVOKABLE double toPixelY(double gy) const;

signals:
    void functionsChanged();
    void viewportChanged();
    void lineWidthChanged();
    void interactiveChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseUngrabEvent() override;
    void wheelEvent(QWheelEvent *event) override;

private:
    struct PixelPoint {
        double x;
        double y;
        bool ok;
    };

    static qsizetype functionCount(QQmlListProperty<GraphFunction> *list);
    static GraphFunction *functionAt(QQmlListProperty<GraphFunction> *list, qsizetype index);
    static void functionAppend(QQmlListProperty<GraphFunction> *list, GraphFunction *fn);
    static void functionClear(QQmlListProperty<GraphFunction> *list);

    PixelPoint samplePoint(const wisp::calc::Expression &expr, double px) const;
    void addSegment(const wisp::calc::Expression &expr, const PixelPoint &a, const PixelPoint &b, int depth,
                    std::vector<QSGGeometry::Point2D> &out) const;
    void addQuad(const PixelPoint &a, const PixelPoint &b, std::vector<QSGGeometry::Point2D> &out) const;
    void buildCurve(const wisp::calc::Expression &expr, std::vector<QSGGeometry::Point2D> &out) const;

    void notifyViewport();

    QList<QPointer<GraphFunction>> m_functions;
    double m_centerX = 0.0;
    double m_centerY = 0.0;
    double m_scale = 50.0;
    double m_lineWidth = 2.5;
    bool m_interactive = true;
    bool m_dragging = false;
    QPointF m_lastMouse;
};

