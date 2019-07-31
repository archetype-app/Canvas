import UIKit

public final class CanvasLayout: UICollectionViewLayout {

    private lazy var zoomGesture: UIPinchGestureRecognizer = {
        return UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
    }()


    private var initialScale: CGFloat = 1
    private var currentScale: CGFloat = 1
    public var allowsZooming: Bool = false {
        didSet {
            collectionView?.removeGestureRecognizer(zoomGesture)

            if collectionView?.minimumZoomScale != collectionView?.maximumZoomScale {
                collectionView?.addGestureRecognizer(zoomGesture)
            }
        }
    }

    @objc private func zoom(_ gesture: UIPinchGestureRecognizer) {
        guard let collectionView = collectionView else { return }

        switch gesture.state {
        case .began:
            initialScale = currentScale
        case .changed:
            currentScale = max(collectionView.minimumZoomScale, min(collectionView.maximumZoomScale, initialScale * gesture.scale))

            let context = UICollectionViewLayoutInvalidationContext()
            context.invalidateItems(at: Array(cachedCellAttributes.keys))
            invalidateLayout(with: context)
        default:
            break
        }
    }

    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        for indexPath in context.invalidatedItemIndexPaths ?? [] {
            cachedCellAttributes[indexPath] = nil
        }

        super.invalidateLayout(with: context)
    }

    private var cachedCellAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]

    public override func prepare() {
        guard let collectionView = collectionView, let dataSource = collectionView.dataSource else { return }

        for section in 0..<(dataSource.numberOfSections?(in: collectionView) ?? 0) {
            for item in 0..<dataSource.collectionView(collectionView, numberOfItemsInSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                if cachedCellAttributes[indexPath] != nil { continue }

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.center = collectionView.center
//                attributes.center.x += currentScale * (120 * CGFloat(indexPath.item))
                attributes.size = CGSize(width: 100, height: 100)
                attributes.transform = CGAffineTransform(scaleX: currentScale, y: currentScale)

                cachedCellAttributes[indexPath] = attributes
            }
        }
    }

    public override var collectionViewContentSize: CGSize {
        var size = cachedCellAttributes.reduce(.zero, { $1.value.frame.union($0) }).size
        size.width *= currentScale
        size.height *= currentScale
        return size
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cachedCellAttributes[indexPath]
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cachedCellAttributes.values.filter { $0.frame.intersects(rect) }
    }

}

// MARK: - Helpers
private extension CanvasLayout {

    func copy(of attributes: UICollectionViewLayoutAttributes?) -> UICollectionViewLayoutAttributes? {
        return attributes?.copy() as? UICollectionViewLayoutAttributes
    }

    func copy(of attributes: [UICollectionViewLayoutAttributes]?) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = attributes else { return nil }
        return NSArray(array: attributes, copyItems: true) as? [UICollectionViewLayoutAttributes]
    }

}
