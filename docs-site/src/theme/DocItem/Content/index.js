import React from 'react';
import {useDoc} from '@docusaurus/plugin-content-docs/client';
import DocItemContent from '@theme-original/DocItem/Content';

function TruthBanner() {
  const {frontMatter} = useDoc();
  const status = frontMatter.status;
  const verifiedAtCommit = frontMatter.verified_at_commit;

  if (!status) {
    return null;
  }

  const shortCommit =
    typeof verifiedAtCommit === 'string'
      ? verifiedAtCommit.slice(0, 12)
      : null;

  return (
    <div className="invariant-truth-banner" data-status={status}>
      <span className="invariant-truth-banner__label">Documentation state</span>
      <strong className="invariant-truth-banner__status">{status}</strong>
      {shortCommit ? (
        <span className="invariant-truth-banner__commit">
          verified against <code>{shortCommit}</code>
        </span>
      ) : null}
    </div>
  );
}

export default function DocItemContentWrapper(props) {
  return (
    <>
      <TruthBanner />
      <DocItemContent {...props} />
    </>
  );
}
