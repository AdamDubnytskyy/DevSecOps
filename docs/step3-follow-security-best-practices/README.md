## Ensure security best practices are followed

#### Tools
- Adapted [kubesec for Security risk analysis for Kubernetes resources](https://kubesec.io/#security-risk-analysis-for-kubernetes-resources)

#### Usage:
[CI workflow](../../.github/workflows/ci.yml) has `security-risk-analysis` step which runs security risk analysis for Kubernetes resources in specified directory.

Whenever kubesec scanner catches any critical issues workflow terminates, until all critical issues are fixed.

E.g.:
```sh
 ❌ k8s/httpbin.yml has critical issues. Please fix listed issues below.
• CapSysAdmin: CAP_SYS_ADMIN is the most privileged capability and should always be avoided (Points: -30)
• Privileged: Privileged containers can allow almost completely unrestricted host access (Points: -30)
• AllowPrivilegeEscalation: Ensure a non-root process can not gain more privileges (Points: -7)
```

After fixing critical issues, CI workflow continues running:
```sh
📄 Scanning: k8s/httpbin.yml
 There are no critical issues.
📄 Scanning: k8s/rbac.yml
 There are no critical issues.
📄 Scanning: k8s/serviceAccount.yml
 There are no critical issues.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SCAN PASSED: No critical security issues found
```

Full `kubesec-security-report` can be downloaded via one of options:
- [latest uploaded artifact](https://github.com/AdamDubnytskyy/DevSecOps/actions/runs/16102760047/artifacts/3472887391)
- [REST API endpoints for GitHub Actions artifacts](https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28)

    E.g.:
    ```sh
    /repos/{owner}/{repo}/actions/artifacts

    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer <YOUR-TOKEN>" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/AdamDubnytskyy/DevSecOps/actions/artifacts

    ``` 
