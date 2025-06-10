// 파일 상단에 추가
enum CellStatus {
  certified,      // 인증 완료
  uncertified,    // 미인증 (과거)
  today,          // 오늘 (인증 가능)
  future,         // 미래
}