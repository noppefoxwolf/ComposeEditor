import UIKit

final class LinkPreviewView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let thumbnailView = UIImageView(image: UIImage(systemName: "doc.text.image"))
        thumbnailView.tintColor = .white
        thumbnailView.backgroundColor = .systemIndigo
        thumbnailView.contentMode = .center
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "ComposeEditor"
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "A UIKit text editor for rich compose screens."
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2

        let urlLabel = UILabel()
        urlLabel.text = "github.com/noppefoxwolf/ComposeEditor"
        urlLabel.font = .preferredFont(forTextStyle: .caption1)
        urlLabel.textColor = .tertiaryLabel

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, urlLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 3

        let contentStack = UIStackView(arrangedSubviews: [thumbnailView, labelsStack])
        contentStack.alignment = .center
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentStack)
        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalToConstant: 72),
            thumbnailView.heightAnchor.constraint(equalToConstant: 72),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
