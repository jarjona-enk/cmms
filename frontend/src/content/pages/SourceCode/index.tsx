import { Link as RouterLink } from 'react-router-dom';
import {
  Box,
  Button,
  Card,
  Container,
  Divider,
  Link,
  List,
  ListItem,
  ListItemText,
  styled,
  Typography
} from '@mui/material';
import DownloadTwoToneIcon from '@mui/icons-material/DownloadTwoTone';
import { Helmet } from 'react-helmet-async';
import Logo from 'src/components/LogoSign';
import { apiUrl } from 'src/config';

const Content = styled(Box)(
  () => `
    display: flex;
    flex: 1;
    width: 100%;
`
);

/**
 * Source code availability notice.
 *
 * This internal deployment of Atlas CMMS is a modified version of the
 * open-source project, used under the GNU Affero General Public License v3
 * (AGPLv3). AGPLv3 §13 requires that all users interacting with the software
 * over a network be offered the Complete Corresponding Source Code of the
 * running version. This page is that offer.
 *
 * The page is intentionally public (no authentication) so the offer is
 * available to every user who interacts with the application.
 */
function SourceCode() {
  return (
    <>
      <Helmet>
        <title>Source Code & Licensing</title>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>
      <Content>
        <Container
          sx={{
            display: 'flex',
            alignItems: 'center',
            flexDirection: 'column'
          }}
          maxWidth="md"
        >
          <Card
            sx={{
              p: 4,
              my: 4
            }}
          >
            <Box textAlign="center" mb={3}>
              <Logo />
              <Typography variant="h2" sx={{ mb: 1 }}>
                Source Code & Open-Source Licensing
              </Typography>
              <Typography
                variant="h4"
                color="text.secondary"
                fontWeight="normal"
              >
                This is an internal tool. Every user has the right to its source
                code.
              </Typography>
            </Box>

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
              , a maintenance management system distributed under the{' '}
              <Link
                href="https://www.gnu.org/licenses/agpl-3.0.html"
                target="_blank"
                rel="noopener noreferrer"
              >
                GNU Affero General Public License, version 3 (AGPLv3)
              </Link>
              . It includes local modifications.
            </Typography>

            <Typography variant="body1" sx={{ mb: 2 }}>
              Under the AGPLv3 (section 13), every user who interacts with this
              software over the network is entitled to receive the{' '}
              <b>complete corresponding source code</b> of the exact version
              running here, including the modifications made for our
              organization. There is no charge for this, and you do not need any
              special permission to ask.
            </Typography>

            <Typography variant="h4" sx={{ mt: 4, mb: 1 }}>
              Download the source code
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              The complete corresponding source for the version running here is
              available as a single archive:
            </Typography>
            <Box sx={{ mb: 3 }}>
              <Button
                variant="contained"
                size="large"
                startIcon={<DownloadTwoToneIcon />}
                component="a"
                href={`${apiUrl}source-code/download`}
              >
                Download source code (.zip)
              </Button>
            </Box>

            <Typography variant="h4" sx={{ mt: 4, mb: 1 }}>
              Prefer to request it from IT?
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              You can also open an <b>IT support ticket</b> requesting the Atlas
              CMMS source code. Please include the following so we can give you
              the correct version:
            </Typography>
            <List sx={{ listStyleType: 'disc', pl: 4, mb: 2 }}>
              <ListItem sx={{ display: 'list-item', py: 0.25 }}>
                <ListItemText primary='Subject line: "Atlas CMMS — source code request (AGPLv3)"' />
              </ListItem>
              <ListItem sx={{ display: 'list-item', py: 0.25 }}>
                <ListItemText primary="The URL of this application as you access it" />
              </ListItem>
              <ListItem sx={{ display: 'list-item', py: 0.25 }}>
                <ListItemText primary="Your preferred delivery method (e.g. repository access or an archive)" />
              </ListItem>
            </List>
            <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
              IT will provide the corresponding source for the version currently
              deployed. The upstream, unmodified project is also publicly
              available at{' '}
              <Link
                href="https://github.com/Grashjs/cmms"
                target="_blank"
                rel="noopener noreferrer"
              >
                github.com/Grashjs/cmms
              </Link>
              .
            </Typography>

            <Divider sx={{ my: 3 }} />

            <Box textAlign="center">
              <Link component={RouterLink} to="/account/login">
                Back to login
              </Link>
            </Box>
          </Card>
        </Container>
      </Content>
    </>
  );
}

export default SourceCode;
