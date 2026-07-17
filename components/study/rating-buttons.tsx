type RatingButtonsProps = {
  selected?: "again" | "hard" | "good" | "easy";
};

const ratings = [
  ["again", "もう一回"],
  ["hard", "難しい"],
  ["good", "正解"],
  ["easy", "簡単"],
] as const;

export function RatingButtons({ selected = "good" }: RatingButtonsProps) {
  return (
    <div className="lab-rating-buttons">
      {ratings.map(([id, label]) => (
        <button key={id} className={selected === id ? "selected" : ""}>
          {label}
        </button>
      ))}
    </div>
  );
}

