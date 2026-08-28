import {
  Box,
  Button,
  Card,
  Container,
  Divider,
  Link,
  Stack,
  Typography
} from '@mui/material';
import DownloadTwoToneIcon from '@mui/icons-material/DownloadTwoTone';
import CodeTwoToneIcon from '@mui/icons-material/CodeTwoTone';
import { Helmet } from 'react-helmet-async';
import { Link as RouterLink } from 'react-router-dom';
import { apiUrl } from 'src/config';

/**
 * In-app About page (authenticated).
 *
 * This internal deployment of Atlas CMMS is a modified version of the
 * open-source project, used under the GNU Affero General Public License v3
 * (AGPLv3). AGPLv3 §13 requires that every user interacting with the software
 * over a network be offered the Complete Corresponding Source Code of the
 * running version, including our local modifications.
 *
 * The source archive is embedded in the jar at build time (see
 * scripts/deploy.sh -> /static/source/atlas-cmms-source.zip) and streamed by
 * SourceCodeController at GET /source-code/download.
 */
function About() {
  const downloadUrl = `${apiUrl}source-code/download`;

  return (
    <>
      <Helmet>
        <title>About & Source Code</title>
      </Helmet>
      <Container sx={{ mt: 4, mb: 4 }} maxWidth="md">
        <Card sx={{ p: 4 }}>
          <Typography variant="h2" sx={{ mb: 1 }}>
            About this application
          </Typography>
          <Typography variant="h4" color="text.secondary" fontWeight="normal">
            An internal, open-source maintenance management system.
          </Typography>

          <Divider sx={{ my: 3 }} />

          <Typography variant="body1" sx={{ mb: 2 }}>
            This application is an internal deployment of{' '}
            <Link
              href="https://github.com/Grashjs/cmms"
              target="_blank"
              rel="noopener noreferrer"
            >
              Atlas CMMS
            </Link>
            , distributed under the{' '}
            <Link
              href="https://www.gnu.org/licenses/agpl-3.0.html"
              target="_blank"
              rel="noopener noreferrer"
            >
              GNU Affero General Public License, version 3 (AGPLv3)
            </Link>
            . It includes modifications made for our organization.
          </Typography>

          <Typography variant="body1" sx={{ mb: 3 }}>
            Under the AGPLv3 (section 13), every user who interacts with this
            software over the network is entitled to receive the{' '}
            <b>complete corresponding source code</b> of the exact version
            running here — including our modifications — at no charge. The
            archive below is generated from, and matches, the deployed version.
          </Typography>

          <Typography variant="h4" sx={{ mt: 2, mb: 1 }}>
            Download the source code
          </Typography>
          <Stack direction="row" spacing={2} sx={{ mb: 3 }} flexWrap="wrap">
            <Button
              variant="contained"
              size="large"
              startIcon={<DownloadTwoToneIcon />}
              component="a"
              href={downloadUrl}
            >
              Download source code (.zip)
            </Button>
            <Button
              variant="outlined"
              size="large"
              startIcon={<CodeTwoToneIcon />}
              component={RouterLink}
              to="/source-code"
            >
              Source & licensing details
            </Button>
          </Stack>

          <Typography variant="body2" color="text.secondary">
            The upstream, unmodified project is also publicly available at{' '}
            <Link
              href="https://github.com/Grashjs/cmms"
              target="_blank"
              rel="noopener noreferrer"
            >
              github.com/Grashjs/cmms
            </Link>
            .
          </Typography>
        </Card>
      </Container>
    </>
  );
}

export default About;
