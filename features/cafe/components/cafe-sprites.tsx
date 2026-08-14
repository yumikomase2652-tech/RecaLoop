type SpriteProps = {
  className?: string;
};

const stroke = "rgba(73, 54, 40, .42)";

export function CafeItemSprite({ imageKey, className }: SpriteProps & { imageKey: string }) {
  switch (imageKey) {
    case "item-reading-chair":
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <path d="M30 40c0-13 11-24 24-24h12c13 0 24 11 24 24v42H30V40Z" fill="#91ABC2" />
          <path d="M22 78h76v18H22z" rx="9" fill="#617B91" />
          <path d="M34 32h52" stroke={stroke} strokeWidth="5" strokeLinecap="round" />
          <path d="M34 96v12M86 96v12" stroke={stroke} strokeWidth="7" strokeLinecap="round" />
        </svg>
      );
    case "item-window-plant":
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <path d="M49 77h24l-4 25H53l-4-25Z" fill="#B7794B" />
          <path d="M61 78c-2-25 1-45 10-61" stroke="#5F7F55" strokeWidth="6" strokeLinecap="round" />
          <ellipse cx="42" cy="43" rx="18" ry="11" fill="#86A977" transform="rotate(-30 42 43)" />
          <ellipse cx="76" cy="38" rx="19" ry="12" fill="#78946C" transform="rotate(24 76 38)" />
          <ellipse cx="62" cy="58" rx="17" ry="11" fill="#95B77F" transform="rotate(-8 62 58)" />
        </svg>
      );
    case "item-coffee-set":
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <ellipse cx="58" cy="83" rx="39" ry="12" fill="#D8BF9C" />
          <path d="M31 40h44v25c0 12-10 22-22 22S31 77 31 65V40Z" fill="#FFF2DA" />
          <path d="M73 48h10c8 0 13 5 13 12s-5 12-13 12h-8" fill="none" stroke="#FFF2DA" strokeWidth="9" strokeLinecap="round" />
          <ellipse cx="53" cy="44" rx="20" ry="7" fill="#6D4A31" />
        </svg>
      );
    case "item-sofa-bench":
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <rect x="18" y="42" width="84" height="46" rx="20" fill="#E7CDB5" />
          <rect x="14" y="68" width="92" height="30" rx="15" fill="#B88965" />
          <path d="M28 98v10M92 98v10" stroke={stroke} strokeWidth="7" strokeLinecap="round" />
        </svg>
      );
    case "item-book-shelf":
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <rect x="20" y="28" width="80" height="62" rx="9" fill="#8C5D3B" />
          <rect x="29" y="36" width="14" height="45" rx="3" fill="#B7794B" />
          <rect x="46" y="36" width="12" height="45" rx="3" fill="#EAD5BD" />
          <rect x="61" y="36" width="15" height="45" rx="3" fill="#78946C" />
          <rect x="79" y="36" width="12" height="45" rx="3" fill="#93AAC4" />
          <path d="M18 91h84" stroke="#6E492E" strokeWidth="8" strokeLinecap="round" />
        </svg>
      );
    case "item-cake-stand":
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <path d="M35 61c0-17 11-29 25-29s25 12 25 29H35Z" fill="#FFF3ED" />
          <circle cx="51" cy="48" r="8" fill="#D7929A" />
          <circle cx="68" cy="45" r="7" fill="#D7929A" />
          <path d="M31 64h58" stroke="#C9A98B" strokeWidth="9" strokeLinecap="round" />
          <path d="M60 69v22M43 94h34" stroke="#B7794B" strokeWidth="8" strokeLinecap="round" />
        </svg>
      );
    case "item-round-table":
    default:
      return (
        <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
          <ellipse cx="60" cy="46" rx="37" ry="19" fill="#B7794B" />
          <path d="M39 52h42l-6 41H45l-6-41Z" fill="#6B4A34" />
          <ellipse cx="60" cy="47" rx="28" ry="12" fill="#D2A26F" opacity=".82" />
        </svg>
      );
  }
}

export function CafeVisitorSprite({ imageKey, className }: SpriteProps & { imageKey: string }) {
  const fill = imageKey === "visitor-sumire" ? "#B8B2EF" : imageKey === "visitor-kohaku" ? "#E2B66B" : "#F7B8C9";
  const cheek = imageKey === "visitor-kohaku" ? "#C98B4A" : "#EE8EAA";
  return (
    <svg className={className} viewBox="0 0 120 120" aria-hidden="true">
      <ellipse cx="60" cy="94" rx="34" ry="10" fill="rgba(75, 48, 31, .16)" />
      <path d="M33 72c0-23 13-42 27-42s27 19 27 42c0 21-12 31-27 31S33 93 33 72Z" fill={fill} />
      <circle cx="49" cy="65" r="4" fill="#26343E" />
      <circle cx="71" cy="65" r="4" fill="#26343E" />
      <circle cx="60" cy="74" r="6" fill="#F2A23A" />
      <circle cx="42" cy="76" r="5" fill={cheek} opacity=".42" />
      <circle cx="78" cy="76" r="5" fill={cheek} opacity=".42" />
    </svg>
  );
}
