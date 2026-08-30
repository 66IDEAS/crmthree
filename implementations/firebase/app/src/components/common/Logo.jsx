import Box from '@mui/material/Box';
import { useTheme } from '@mui/material/styles';

export default function Logo({ size = 32, by = false, ...props }) {
  const theme = useTheme();
  const mode = theme.palette.mode === 'dark' ? 'dark' : 'light';
  const src = by ? `/crmthree-by-${mode}.svg` : `/crmthree-${mode}.svg`;

  return (
    <Box
      component="img"
      src={src}
      alt="CRMTHREE"
      {...props}
      sx={{ height: size, width: 'auto', ...props.sx }}
    />
  );
}
