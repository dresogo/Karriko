export interface Review {
  id: number
  author: string
  rating: number
  text: string
  isAnonymous: boolean
}

function StarRating({ rating, max = 5 }: { rating: number; max?: number }) {
  return (
    <div className="flex gap-0.5">
      {Array.from({ length: max }).map((_, i) => (
        <span
          key={i}
          className={`text-xs ${
            i < rating ? 'text-[#1a3a2a]' : 'text-[#d1d5db]'
          }`}
        >
          ★
        </span>
      ))}
    </div>
  )
}

export default function ReviewCard({ review }: { review: Review }) {
  return (
    <div className="karriko-card flex flex-col gap-3">
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-full bg-[#f3f4f6] flex items-center justify-center text-lg text-[#9ca3af]">
          👤
        </div>
        <div>
          <h3 className="font-serif-display text-sm font-semibold text-[#111827]">
            {review.author}
          </h3>
          <StarRating rating={review.rating} />
        </div>
      </div>
      <p className="text-xs text-[#4b5563] leading-relaxed">
        "{review.text}"
      </p>
    </div>
  )
}
