import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Stepper from '@mui/material/Stepper';
import Step from '@mui/material/Step';
import StepLabel from '@mui/material/StepLabel';
import { useUI } from '../../contexts/UIContext';
import { t } from '../../services/TranslationService';

export default function DealStageProgress({ stages, currentStageId, result }) {
  const { isMobile } = useUI();

  if (!stages || stages.length === 0) return null;

  const activeIndex = stages.findIndex((s) => s.id === currentStageId);
  const isWon = result === 'Won';
  const isLost = result === 'Lost';

  return (
    <Paper variant="outlined" sx={{ p: 2, mx: 2, mb: 2 }}>
      <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>
        {t('section.deal_progress', 'Deal Progress')}
      </Typography>
      <Stepper
        activeStep={isWon ? stages.length : activeIndex}
        alternativeLabel={!isMobile}
        orientation={isMobile ? 'vertical' : 'horizontal'}
        sx={{
          '& .MuiStepIcon-root.Mui-completed': { color: 'success.main' },
          '& .MuiStepIcon-root.Mui-active': {
            color: isLost ? 'error.main' : 'primary.main',
          },
        }}
      >
        {stages.map((stage) => (
          <Step key={stage.id} completed={isWon || stages.indexOf(stage) < activeIndex}>
            <StepLabel error={isLost && stage.id === currentStageId}>
              {stage.name}
            </StepLabel>
          </Step>
        ))}
      </Stepper>
    </Paper>
  );
}
