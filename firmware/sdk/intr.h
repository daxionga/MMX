#ifndef _INTR_H_
#define _INTR_H_

static inline void irq_enable(unsigned int en)
{
       __asm__ __volatile__("wcsr IE, %0" : : "r" (en));
}

static inline unsigned int irq_getmask(void)
{
       unsigned int mask;
       __asm__ __volatile__("rcsr %0, IM" : "=r" (mask));
       return mask;
}

static inline void irq_setmask(unsigned int mask)
{
       __asm__ __volatile__("wcsr IM, %0" : : "r" (mask));
}

static inline unsigned int irq_pending(void)
{
       unsigned int pending;
       __asm__ __volatile__("rcsr %0, IP" : "=r" (pending));
       return pending;
}

static inline void irq_ack(unsigned int mask)
{
       __asm__ __volatile__("wcsr IP, %0" : : "r" (mask));
}

static inline unsigned int irq_getie(void)
{
       unsigned int ie;
       __asm__ __volatile__("rcsr %0, IE" : "=r" (ie));
       return ie;
}

static inline void irq_setie(unsigned int ie)
{
       __asm__ __volatile__("wcsr IE, %0" : : "r" (ie));
}

void isr(void);

#endif	/* _INTR_H_ */
