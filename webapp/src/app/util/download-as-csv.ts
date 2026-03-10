// small helper to turn header+rows into a downloadable CSV file
export function downloadAsCSV(
  header: string[],
  rows: string[][],
  filename: string
): void {
  const all = [header, ...rows];
  const csv = all
    .map((r) =>
      r
        .map((v) => `"${String(v).replace(/"/g, '""')}"`)
        .join(',')
    )
    .join('\r\n');

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.setAttribute('href', url);
  a.setAttribute('download', `${filename}.csv`);
  a.style.visibility = 'hidden';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}
