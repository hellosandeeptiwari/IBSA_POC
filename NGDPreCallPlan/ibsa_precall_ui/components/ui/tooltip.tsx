'use client'

import * as React from "react"
import * as ReactDOM from "react-dom"
import { Info } from "lucide-react"

interface TooltipProps {
  content: string
  children?: React.ReactNode
}

export function Tooltip({ content, children }: TooltipProps) {
  const [isVisible, setIsVisible] = React.useState(false)
  const [coords, setCoords] = React.useState<{ top: number; left: number } | null>(null)
  const triggerRef = React.useRef<HTMLDivElement | null>(null)

  const updatePosition = React.useCallback(() => {
    const el = triggerRef.current
    if (!el) return
    const rect = el.getBoundingClientRect()
    setCoords({
      top: rect.top - 12, // Position above the trigger with more space
      left: rect.left + rect.width / 2,
    })
  }, [])

  React.useEffect(() => {
    if (!isVisible) return
    updatePosition()
    const onScroll = () => updatePosition()
    const onResize = () => updatePosition()
    window.addEventListener('scroll', onScroll, true)
    window.addEventListener('resize', onResize)
    return () => {
      window.removeEventListener('scroll', onScroll, true)
      window.removeEventListener('resize', onResize)
    }
  }, [isVisible, updatePosition])

  return (
    <div className="inline-flex items-center">
      <div
        ref={triggerRef}
        onMouseEnter={() => setIsVisible(true)}
        onMouseLeave={() => setIsVisible(false)}
        className="inline-flex items-center cursor-help"
      >
        {children || <Info className="h-3 w-3 ml-1 text-gray-400 hover:text-gray-600" />}
      </div>
      {isVisible && coords && typeof document !== 'undefined'
        ? ReactDOM.createPortal(
            <div
              style={{
                position: 'fixed',
                top: coords.top,
                left: coords.left,
                transform: 'translate(-50%, -100%)',
                zIndex: 99999,
                pointerEvents: 'none',
              }}
              className="mb-2 px-4 py-2.5 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-2xl border border-gray-700 whitespace-normal max-w-sm leading-relaxed"
            >
              {content}
              <div className="absolute" style={{ top: '100%', left: '50%', transform: 'translate(-50%, -2px)' }}>
                <div className="border-[6px] border-transparent border-t-gray-900"></div>
              </div>
            </div>,
            document.body
          )
        : null}
    </div>
  )
}
